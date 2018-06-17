# ActiveStorage::Openstack
This rails plugin wraps the OpenStack Swift provider as an Active Storage service.
It is a rewrite/refactor of [activestorage-openstack](https://github.com/jeffreyguenther/activestorage-openstack).

## Usage
in `storage.yml`, create an entry with the following keys:
```yaml
dev_openstack:
  service: OpenStack
  container: <container name>
  credentials:
    openstack_auth_url: <auth url>
    openstack_username: <username>
    openstack_api_key: <password>
    openstack_region: <region>
    openstack_temp_url_key: <temp url key>
  connection_options: # optional
    chunk_size: 2097152 # 2MBs - 1MB is the default
```

You can create as many entries as you would like for your different environments.
Then register the provider in your `environment.rb`

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

## Testing
From the root of the plugin, copy the following file and fill in the appropriate credentials
```bash
$ cp test/configurations.example.yml test/configurations.yml
```
And then run the tests like this:
```bash
$ bin/test
```

## Contributions
Contributions are welcome. Feel free to open any issues if you encounter any bug, or if you want to suggest a feature.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
