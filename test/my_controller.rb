class MyController < ApplicationController
  cattr_accessor :counter
  def index
    render :text => counter
    self.counter += 1
  end
  def redirect
    redirect_to :action => :index
  end
end