$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "active_storage/openstack/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "activestorage-openstack"
  s.version     = ActiveStorage::Openstack::VERSION
  s.authors     = ["chaadow"]
  s.email       = ["chaadow@msn.com"]
  s.homepage    = "http://google.com"
  s.summary     = "Summary of ActiveStorage::Openstack."
  s.description = "Description of ActiveStorage::Openstack."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

s.add_dependency "activestorage", "~> 5.2.0"
 s.add_dependency "fog-openstack"
 s.add_dependency "mime-types"

  s.add_development_dependency "sqlite3"
end
