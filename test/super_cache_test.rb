require File.expand_path('test_helper', File.dirname(__FILE__))

class MyController < ApplicationController
  super_caches_page :index
  def index
    @counter ||= 0
    render :text => @counter
  end
end

class SuperCacheTest < ActionController::TestCase
  tests MyController
  test "should get index successfully and store cache" do
    get :index
    assert_response :success
    assert_equal '0', @response.body.strip
    assert_equal '0', Rails.cache.read('test.host/my', :raw => true)
  end 
  def teardown
    Rails.cache.clear
  end
end