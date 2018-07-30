# ActiveStorage::Openstack
This rails plugin wraps the OpenStack Swift provider as an Active Storage service.
It is a rewrite/refactor of [activestorage-openstack](https://github.com/jeffreyguenther/activestorage-openstack).

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'activestorage-openstack'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install activestorage-openstack
```

## Usage
in `config/storage.yml`, in your Rails app, create an entry with the following keys:
```yaml
dev_openstack:
  service: OpenStack
  container: <container name> # Container name for your OpenStack provider
  credentials:
    openstack_auth_url: <auth url>
    openstack_username: <username>
    openstack_api_key: <password>
    openstack_region: <region>
    openstack_temp_url_key: <temp url key> # Mandatory, instructions below
  connection_options: # optional
    chunk_size: 2097152 # 2MBs - 1MB is the default
```

You can create as many entries as you would like for your different environments. For instance: `dev_openstack` for development, `test_openstack` for test environment, and `prod_openstack` for production. This way you can choose the appropriate container for each scenario.

Then register the provider in your `config/{environment}.rb` (`config/development.rb`/`config/test.rb`/`config/production.rb`)

For example, for the `dev_openstack` entry above, change the `config` variable in `config/development.rb` like the following:
```ruby
# Store uploaded files on the local file system (see config/storage.yml for options)
config.active_storage.service = :dev_openstack
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

OpenStack Swift handles the Content-Type of an object differently from other object storage services. You cannot overwrite the Content-Type via a temp URL. This gem will try very hard to set the right Content-Type for an object at object creation (eigther via server upload or direct upload) but this is wrong in edge cases (e.g. you use direct upload and the browser provides a wrong mime type).

For this edge cases `ActiveStorage::Blob::Identifiable` downloads the first 4K of a file, identifies the content type and saves the result in the database. For `ActiveStorage::Openstack` we also need to update the Content-Type of the object. This is done automatically with a little monkey patch.

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
