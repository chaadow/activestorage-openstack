require 'fog/openstack'

module ActiveStorage
  class Service::OpenStackService < Service
    attr_reader :client, :container

    def initialize(container:, credentials:, connection_options: {})
      settings = if connection_options.present?
                   credentials.reverse_merge(connection_options: connection_options)
                 else
                   credentials
                 end
      @client = Fog::Storage::OpenStack.new(settings)
      @container = Fog::OpenStack.escape(container)
    end

    def upload(key, io, checksum: nil)
      instrument :upload, key: key, checksum: checksum do
        params = {}.merge(etag: convert_base64digest_to_hexdigest(checksum))
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
          object_for(key, &block).body
        end
      else
        instrument :download, key: key do
          object_for(key).body
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        object_for(key).body[range]
      end
    end


    def delete(key)
      instrument :delete, key: key do
        begin
          client.delete_object(container, key)
        rescue Fog::Storage::OpenStack::NotFound
          false
        end
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
        begin
          answer = object_for(key)
          payload[:exist] = answer
        rescue Fog::Storage::OpenStack::NotFound
          payload[:exist] = false
        end
      end
    end

    def url(key, expires_in:, disposition:, filename:, content_type:)
      instrument :url, key: key do |payload|
        expire_at = unix_timestamp_expires_at(expires_in)

        generated_url = client.get_object_https_url(container, key, expire_at, disposition: disposition, filename: filename, content_type: content_type)

        payload[:url] = generated_url

        generated_url
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
      instrument :url, key: key do |payload|
        expire_at = unix_timestamp_expires_at(expires_in)
        generated_url = client.create_temp_url(container,
                                               key,
                                               expire_at,
                                               'PUT',
                                               port: 443,
                                               scheme: "https",
                                               content_type: content_type,
                                               content_length: content_length,
                                               etag: convert_base64digest_to_hexdigest(checksum))

        payload[:url] = generated_url

        generated_url
      end
    end

    def headers_for_direct_upload(key, content_type:, content_length:, checksum:)
      {
        'Content-Type' => content_type,
        'Etag' => convert_base64digest_to_hexdigest(checksum),
        'Content-Length' => content_length
      }
    end

    private

    def object_for(key, &block)
      client.get_object(container, key, &block)
    end

    # ActiveStorage sends a `Digest::MD5.base64digest` checksum
    # OpenStack expects a `Digest::MD5.hexdigest` Etag
    def convert_base64digest_to_hexdigest(base64digest)
      base64digest.unpack('m0').first.unpack('H*').first if base64digest
    end

    def unix_timestamp_expires_at(seconds_from_now)
      Time.zone.now.advance(seconds: seconds_from_now).to_i
    end

    def format_range(range)
      " bytes=#{range.begin}-#{range.exclude_end? ? range.end - 1 : range.end}"
    end


  end
end
