module ActiveStorage
  module Openstack
    class Railtie < ::Rails::Railtie
      initializer "active_storage_openstack.blob" do
        ActiveSupport.on_load(:active_storage_blob) do |klass|
          klass.after_commit do |blob|
            # overwrite conten type if identification ran and 
            # the service responds to change_content_type 
            if blob.identified? && !blob.content_type.blank? && 
               blob.service.respond_to?(:change_content_type)
              blob.service.change_content_type(blob.key, blob.content_type)
            end
          end
        end
      end
    end
  end
end
