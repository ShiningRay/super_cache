# SuperCache

SuperCache for rails is a caching middleware inspired by the "SuperCache" plugin
for WordPress.

## Installation

Add this line to your application's Gemfile:

    gem 'super_cache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install super_cache

## Usage

Just call `super_caches_page` inside your controller with the action names to be cached.

```ruby
class MyController < ApplicationController
  super_caches_page :index
  def index
    # action to be 
  edn
end
```

Super_cache will store the response body into `Rails.cache`. The next time requesting
that action will get the same result.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
