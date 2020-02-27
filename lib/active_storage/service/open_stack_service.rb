require 'fog/openstack'

module ActiveStorage
  class Service::OpenStackService < Service
    attr_reader :client, :container

    def initialize(container:, credentials:, connection_options: {})
      settings = credentials.reverse_merge(connection_options: connection_options)

      @client = Fog::OpenStack::Storage.new(settings)
      @container = Fog::OpenStack.escape(container)
    end

    def upload(key, io, checksum: nil, disposition: nil, content_type: nil, filename: nil, **)
      instrument :upload, key: key, checksum: checksum do
        params = { 'Content-Type' => content_type || guess_content_type(io) }
        params['ETag'] = convert_base64digest_to_hexdigest(checksum) if checksum
        if disposition && filename
          params['Content-Disposition'] =
            content_disposition_with(type: disposition, filename: filename)
        end

        begin
          client.put_object(container, key, io, params)
        rescue Excon::Error::UnprocessableEntity
          raise ActiveStorage::IntegrityError
        end
      end
    end

    def download(key, &block)
      if block_given?
        instrument :streaming_download, key: key do
          object_for(key, &block)
        end
      else
        instrument :download, key: key do
          object_for(key).body
        end
      end
    rescue Fog::OpenStack::Storage::NotFound
      raise ActiveStorage::FileNotFoundError if defined?(ActiveStorage::FileNotFoundError)
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        chunk_buffer = []

        object_for(key) do |chunk|
          chunk_buffer << chunk
        end

        chunk_buffer.join[range]
      rescue Fog::OpenStack::Storage::NotFound
        raise ActiveStorage::FileNotFoundError if defined?(ActiveStorage::FileNotFoundError)
      end
    end

    def delete(key)
      instrument :delete, key: key do
        client.delete_object(container, key)
      rescue Fog::OpenStack::Storage::NotFound
        false
      end
    end

    def delete_prefixed(prefix)
      instrument :delete, prefix: prefix do
        directory = client.directories.get(container)
        filtered_files = client.files(directory: directory, prefix: prefix)
        filtered_files = filtered_files.map(&:key)

        client.delete_multiple_objects(container, filtered_files)
      end
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        answer = object_for(key)
        payload[:exist] = answer.present?
      rescue Fog::OpenStack::Storage::NotFound
        payload[:exist] = false
      end
    end

    def url(key, expires_in:, disposition:, filename:, **)
      instrument :url, key: key do |payload|
        expire_at = unix_timestamp_expires_at(expires_in)
        generated_url =
          client.get_object_https_url(
            container,
            key,
            expire_at,
            filename: filename
          )
        generated_url += '&inline' if disposition.to_s != 'attachment'
        # unfortunately OpenStack Swift cannot overwrite the content type of an object via a temp url
        # so we just ignore the content_type argument here
        payload[:url] = generated_url

        generated_url
      end
    end

    def url_for_direct_upload(key, expires_in:, **)
      instrument :url, key: key do |payload|
        expire_at = unix_timestamp_expires_at(expires_in)
        generated_url = client.create_temp_url(container,
                                               key,
                                               expire_at,
                                               'PUT',
                                               port: 443,
                                               scheme: 'https')

        payload[:url] = generated_url

        generated_url
      end
    end

    def headers_for_direct_upload(_key, content_type:, checksum:, **)
      {
        'Content-Type' => content_type,
        'ETag' => convert_base64digest_to_hexdigest(checksum)
      }
    end

    def update_metadata(key, content_type:, disposition: nil, filename: nil, **)
      instrument :update_metadata, key: key, content_type: content_type, disposition: disposition do
        params = { 'Content-Type' => content_type }
        if disposition && filename
          params['Content-Disposition'] =
            content_disposition_with(type: disposition, filename: ActiveStorage::Filename.wrap(filename))
        end
        client.post_object(container,
                           key,
                           params)
        true
      rescue Fog::OpenStack::Storage::NotFound
        raise ActiveStorage::FileNotFoundError if defined?(ActiveStorage::FileNotFoundError)
      end
    end

  private

    def object_for(key, &block)
      client.get_object(container, key, &block)
    end

    # ActiveStorage sends a `Digest::MD5.base64digest` checksum
    # OpenStack expects a `Digest::MD5.hexdigest` ETag
    def convert_base64digest_to_hexdigest(base64digest)
      base64digest.unpack1('m0').unpack1('H*')
    end

    def unix_timestamp_expires_at(seconds_from_now)
      Time.current.advance(seconds: seconds_from_now).to_i
    end

    def guess_content_type(io)
      Marcel::MimeType.for io,
                           name: io.try(:original_filename),
                           declared_type: io.try(:content_type)
    end
  end
end
