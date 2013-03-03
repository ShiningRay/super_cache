require 'rubygems'
require 'bundler'

Bundler.setup

require 'test/unit'
#require 'mocha/setup'

ENV["RAILS_ENV"] = "test"
RAILS_ROOT = "anywhere"

require "active_support"
require "active_model"
require "action_controller"

I18n.load_path << File.join(File.dirname(__FILE__), 'locales', 'en.yml')
I18n.reload!

class ApplicationController < ActionController::Base; end
class Rails
  cattr_accessor :cache
  @@cache = ActiveSupport::Cache::MemoryStore.new
end
# Add IR to load path and load the main file
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'super_cache'

ActionController::Base.view_paths = File.join(File.dirname(__FILE__), 'views')
ActionController::Base.perform_caching=true
SuperCache::Routes = ActionDispatch::Routing::RouteSet.new
SuperCache::Routes.draw do
  match ':controller(/:action(/:id))'
  match ':controller(/:action)'
  resources 'posts'
  root :to => 'posts#index'
end

ActionController::Base.send :include, SuperCache::Routes.url_helpers

class ActiveSupport::TestCase
  setup do
    @routes = SuperCache::Routes
  end
end
