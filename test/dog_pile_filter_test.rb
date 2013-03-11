require File.expand_path('test_helper', File.dirname(__FILE__))
require File.expand_path('my_controller', File.dirname(__FILE__))

class MyController < ApplicationController
  super_caches_page :my, :lock => true
end

class DogPileFilterTest < ActionController::TestCase
  tests MyController
  setup do
    MyController.counter = 0
  end  
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
    ActionController::Base.perform_caching=true
  end
  test "should not cache when response is redirected" do
    get :redirect
    assert_response :redirect
    assert_nil Rails.cache.read('test.host/redirect', :raw => true)
  end
end