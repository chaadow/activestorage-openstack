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
        @container = @client.directories.get(container)
      end

      def upload(key, io, checksum: nil)
        instrument :upload, key: key, checksum: checksum do
          file = container.files.create(key: key, body: io)
          file.reload

          if checksum.present? && convert_to_base64_digest(file.etag) != checksum
            file.destroy
            raise ActiveStorage::IntegrityError
          end
        end
      end

      def download(key)
        instrument :download, key do

          File.open(key, 'w') do | f |
            container.files.get(key) do | data, remaining, content_length |
              f.syswrite data
            end
          end
        end
      end

      def delete(key)
        instrument :delete, key do
          file_for(key).destroy
        end
      end

      def exist?(key)
        instrument :exist, key do |payload|
          answer = file_for(key).present?
          payload[:exist] = answer
          answer
        end
      end

      def url(key, expires_in:, disposition:, filename:, content_type:)
        instrument :url, key do |payload|
          expire_at = unix_timestamp_expires_at(expires_in)
          generated_url = file_for(key).url(expire_at)

          payload[:url] = generated_url

          generated_url
        end
      end

      def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:)
        instrument :url, key do |payload|
          # expire_at = unix_timestamp_expires_at(expires_in)
          # generated_url = client.create_temp_url(container.key, key, expire_at, 'PUT')
          #
          # payload[:url] = generated_url
          #
          # generated_url
        end
      end

      def headers_for_direct_upload(_key, content_type:, content_length:, checksum:, **)
        { 'Content-Type' => content_type,
          'Etag' => checksum, 'Content-Length' => content_length
        }
      end

    private

      def unix_timestamp_expires_at(seconds_from_now)
        Time.current.advance(seconds: seconds_from_now).to_i
      end

      def file_for(key)
        container.files.get(key)
      end

      def convert_to_base64_digest(hex_digest)
        [[hex_digest].pack('H*')].pack('m0')
      end
    end
  end
