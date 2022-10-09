

# ActiveStorage::Openstack 
![Gem](https://img.shields.io/gem/v/activestorage-openstack?style=for-the-badge) ![Build Status](https://img.shields.io/github/workflow/status/chaadow/activestorage-openstack/Ruby?style=for-the-badge) ![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability-percentage/chaadow/activestorage-openstack?style=for-the-badge)

This rails plugin wraps the OpenStack Swift provider as an Active Storage service. 

Compatible with rails `6.0.x`, `6.1.x`, `7.0.x` as well as `rails main branch` (edge).

Compatible with ruby `2.5`, `2.6`, `2.7`, `3.0`, `3.1`.

**This gem currently supports `fog-openstack` version `~ 1.0`**

## Installation
Add this line to your application's Gemfile ( Add the second line for ruby 3/3.1 support)

```ruby
gem 'activestorage-openstack', '1.6.0'
gem 'fog-openstack', github: 'chaadow/fog-openstack' # Temporary, for ruby 3 support, until the PR is merged and released
```

## Usage
in `config/storage.yml`, in your Rails app, you can create as many entries as
you wish. Here is an example with rails 6.1 new support for public containers

```yaml

# Here you can have the common authentication credentials and config
# by defining a YAML anchor
default_config: &default_config
  service: OpenStack
  credentials:
    openstack_auth_url: <auth url>
    openstack_username: <username>
    openstack_api_key: <password>
    openstack_region: <region>
    openstack_temp_url_key: <temp url key> # Mandatory, instructions below
  connection_options: # optional
    chunk_size: 2097152 # 2MBs - 1MB is the default

# starting from rails 6.1, you can have a public container generating public
# URLs
public_openstack:
  <<: *default_config # we include the anchor defined above
  public: true # important ; to tell rails that this is a public container
  container: <container name> # Container name for your public OpenStack provider

# this config will generate signed/expired URLs (aka. private URLs)
private_openstack:
  <<: *default_config # we include the anchor defined above
  public: false # Optional in this case, because false is the default value
  container: <container name> # Container name for your private OpenStack provider
```

You can create as many entries as you would like for your different environments. For instance: `public_openstack` for development, `test_openstack` for test environment, and `prod_openstack` for production. This way you can choose the appropriate container for each scenario.

Then register the provider in your `config/{environment}.rb` (`config/development.rb`/`config/test.rb`/`config/production.rb`)

For example, for the `public_openstack` entry above, change the `config` variable in `config/development.rb` like the following:
```ruby
# Store uploaded files on the local file system (see config/storage.yml for options)
config.active_storage.service = :public_openstack
```

## Setting up a container

From your OpenStack provider website, create or sign in to your account.
Then from your dashboard, create a container, and save the configuration generated.

It is a good practice to create a separate container for each of your environments.
Once safely saved, you can add them to your storage configuration in your Rails application.
## `temp_url_key` configuration

the `openstack_temp_url_key` in your configuration is mandatory for generating URLs (expiring ones) as well as for Direct Upload. You can set it up with `Swift` or with the `Fog/OpenStack` gem. More instructions on how to set it up with Swift are found [HERE](https://docs.openstack.org/swift/latest/api/temporary_url_middleware.html#secret-keys)

The next version of this plugin, will add a rails generator, or expose a method that would use the built-in method from `Fog::OpenStack::Real` to generate the key.

## `ActiveStorage::Openstack`'s Content-Type handling

OpenStack Swift handles the Content-Type of an object differently from other
object storage services.
You cannot overwrite the Content-Type via a temp URL. This gem will try very
hard to set the right Content-Type for an object at
object creation (either via server upload or direct upload) but this can be
wrong in some edge cases (e.g. you use direct upload and the browser provides
a wrong mime type).
Thankfully, by implementing the rails hook `#update_metadata`
this will update the object in your container by setting the new content type
after it's been uploaded.

## Testing
First, run `bundle` to install the gem dependencies (both development and production)
```bash
$ bundle
```
Then, from the root of the plugin, copy the following file and fill in the appropriate credentials.
**Preferably, set up a container for your testing, separate from production.**
```bash
$ cp test/configurations.example.yml test/configurations.yml
```
And then run the tests:
```bash
$ bin/test
```

## Contributions
Contributions are welcome. Feel free to open any issues if you encounter any bug, or if you want to suggest a feature by clicking here: https://github.com/chaadow/activestorage-openstack/issues

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
