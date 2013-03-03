require File.expand_path('test_helper', File.dirname(__FILE__))

class MyController < ApplicationController
  super_caches_page :index
  def index
    @counter ||= 0
    render :text => @counter
  end
  def redirect
    redirect_to :action => :index
  end
end
module SuperCacheTestHelper
  def teardown
    Rails.cache.clear
  end
end
class SuperCacheTest < ActionController::TestCase
  tests MyController
  test "should get index successfully and store cache and then get the cached version" do
    get :index
    assert_response :success
    assert_equal '0', @response.body.strip
    assert_equal '0', Rails.cache.read('test.host/my', :raw => true)
    get :index
    assert_response :success    
    assert_equal '0', @response.body.strip
  end 
  test "should not cache when performing cache is disabled" do
    ActionController::Base.perform_caching=false
    get :index
    assert_response :success
    assert_equal '0', @response.body.strip
    assert_nil Rails.cache.read('test.host/my', :raw => true)
  end
  test "should not cache when response is redirected" do
    get :redirect
    assert_response :redirect
    assert_nil Rails.cache.read('test.host/redirect', :raw => true)
  end
  def teardown
    Rails.cache.clear
  end
end