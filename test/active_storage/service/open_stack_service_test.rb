# frozen_string_literal: true

require 'test_helper'
require "active_support/core_ext/securerandom"
require "net/http"

if SERVICE_CONFIGURATIONS[:openstack]
  class ActiveStorage::Service::OpenStackServiceTest < ActiveSupport::TestCase
    FIXTURE_KEY  = SecureRandom.base58(24)
    FIXTURE_DATA = "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\020\000\000\000\020\001\003\000\000\000%=m\"\000\000\000\006PLTE\000\000\000\377\377\377\245\331\237\335\000\000\0003IDATx\234c\370\377\237\341\377_\206\377\237\031\016\2603\334?\314p\1772\303\315\315\f7\215\031\356\024\203\320\275\317\f\367\201R\314\f\017\300\350\377\177\000Q\206\027(\316]\233P\000\000\000\000IEND\256B`\202".dup.force_encoding(Encoding::BINARY)

    setup do
      @service = ActiveStorage::Service.configure(:openstack, SERVICE_CONFIGURATIONS)
      @service.upload(FIXTURE_KEY, StringIO.new(FIXTURE_DATA))
    end

    teardown do
      @service.delete FIXTURE_KEY
    end

    test "uploading with integrity" do
      begin
        key  = SecureRandom.base58(24)
        data = "Some random string!"

        @service.upload(key, StringIO.new(data), checksum: Digest::MD5.base64digest(data))

        assert_equal data, @service.download(key)
      ensure
        @service.delete key
      end
    end

    test "uploading without integrity" do
      begin
        key  = SecureRandom.base58(24)
        data = "Some random string!"

        assert_raises(ActiveStorage::IntegrityError) do
          @service.upload(key,
                          StringIO.new(data),
                          checksum: Digest::MD5.base64digest("bad string"))
        end

        assert_not @service.exist?(key)
      ensure
        @service.delete key
      end
    end

    test "downloading" do
      assert_equal FIXTURE_DATA, @service.download(FIXTURE_KEY)
    end

    test "downloading in chunks" do
      key = SecureRandom.base58(24)
      chunk_size = @service.client.instance_values["connection_options"][:chunk_size] || 1.megabyte # default for OpenStack
      expected_chunks = ["a" * chunk_size, "b"]
      actual_chunks = []

      begin
        @service.upload key, StringIO.new(expected_chunks.join)

        @service.download key do |chunk|
          actual_chunks << chunk
        end

        assert_equal expected_chunks, actual_chunks, "Downloaded chunks did not match uploaded data"
      ensure
        @service.delete key
      end
    end

    test "downloading partially" do
      assert_equal "\x10\x00\x00", @service.download_chunk(FIXTURE_KEY, 19..21)
      assert_equal "\x10\x00\x00", @service.download_chunk(FIXTURE_KEY, 19...22)
    end

    test "signed URL generation" do
      url = @service.url(FIXTURE_KEY, expires_in: 5.minutes,
                                      disposition: :inline,
                                      filename: ActiveStorage::Filename.new("avatar.png"), content_type: "image/png")

      assert_match SERVICE_CONFIGURATIONS[:openstack][:container], url
    end

    test "direct upload" do
      begin
        key      = SecureRandom.base58(24)
        data     = "Something else entirely!"
        checksum = Digest::MD5.base64digest(data)
        hex_checksum = Digest::MD5.hexdigest(data) # For OpenStack

        url = @service.url_for_direct_upload(key,
                                             expires_in: 5.minutes,
                                             content_type: "text/plain",
                                             content_length: data.size,
                                             checksum: checksum)

        uri = URI.parse url
        request = Net::HTTP::Put.new uri.request_uri
        request.body = data
        request.add_field "Content-Type", "text/plain"
        request.add_field "Etag", hex_checksum
        request.add_field "Content-Length", data.size
        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.request request
        end

        assert_equal data, @service.download(key)
      ensure
        @service.delete key
      end
    end

    test "existing" do
      assert @service.exist?(FIXTURE_KEY)
      assert_not @service.exist?(FIXTURE_KEY + "abc")
    end

    test "deleting" do
      @service.delete FIXTURE_KEY
      assert_not @service.exist?(FIXTURE_KEY)
    end

    test "deleting nonexistent key" do
      assert_not @service.delete SecureRandom.base58(24)
    end

    test "deleting by prefix" do
      begin
        @service.upload("a/a/a", StringIO.new(FIXTURE_DATA))
        @service.upload("a/a/b", StringIO.new(FIXTURE_DATA))
        @service.upload("a/b/a", StringIO.new(FIXTURE_DATA))

        @service.delete_prefixed("a/a/")

        assert_not @service.exist?("a/a/a")
        assert_not @service.exist?("a/a/b")

        assert @service.exist?("a/b/a")
      ensure
        @service.delete("a/a/a")
        @service.delete("a/a/b")
        @service.delete("a/b/a")
      end
    end
  end
else
  puts "Skipping OpenStack Service tests because no OpenStack configuration was supplied"
end
