require File.expand_path('test_helper', File.dirname(__FILE__))
require File.expand_path('my_controller', File.dirname(__FILE__))
Rails.cache = ActiveSupport::Cache::MemCacheStore.new
class Model
  include SuperCache::CacheMetaInfo
  include SuperCache::CacheMetaInfo::MemCacheStore
  attr_accessor :id
  def initialize(id)
    @id = id
  end
end
class TestController < ApplicationController
  super_caches_page :index, :subject => Proc.new { @model }
  def index
    $model = @model = Model.new(10)
    render :text => @model.id
  end
end
class CacheMetaIntoTest < ActionController::TestCase
  tests TestController
  test "should get index" do
    get :index
    assert_response :success
    assert_equal '10', @response.body.strip
    assert_equal '10', Rails.cache.read('test.host/test', :raw => true)
    assert_equal $model.key_for_cached_keys, 'Model:10:cached_keys'
    assert_equal $model.cached_keys.size, 1
    assert_equal $model.cached_keys[0], 'test.host/test'
    $model.clear_related_caches
    assert_nil Rails.cache.read('test.host/test', :raw => true)
  end 
end