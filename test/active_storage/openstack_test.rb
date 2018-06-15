require 'test_helper'

class ActiveStorage::Openstack::Test < ActiveSupport::TestCase
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
      data = "Random"
      @service.upload(key, StringIO.new(data), checksum: Digest::MD5.base64digest(data))

      assert_equal data, @service.download(key)
    ensure
      @service.delete key
    end
  end

  test "downloading" do
    assert_equal FIXTURE_DATA, @service.download(FIXTURE_KEY)
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
    assert_nothing_raised do
      @service.delete SecureRandom.base58(24)
    end
  end
end
