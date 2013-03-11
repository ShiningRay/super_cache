require "super_cache/version"
require 'uri'
require 'fileutils'
# for static-caching the generated html pages

module SuperCache
  autoload :Lock,          'super_cache/lock'
  autoload :DogPileFilter, 'super_cache/dog_pile_filter'
  autoload :SimpleFilter,  'super_cache/simple_filter'

  def self.included(base)
    base.class_attribute :cache_filter
    base.extend(ClassMethods)
  end

  module ClassMethods
    def super_caches_page(*pages)
      return unless cache_configured?
      options = pages.extract_options!
<<<<<<< HEAD
      filter_options = options.extract!(:if, :unless)
      filter_options[:only] = (Array(options[:only]) + pages).flatten
      cache_filter_class = options.delete(:lock) ? DogPileFilter : SimpleFilter
      around_filter filter_options do |controller, action|
        cache_filter_class.filter(options.dup, controller, action)
      end
=======
      filter_options = options.extract!(:if, :unless).merge(:only => (Array(options[:only]) + pages).flatten)
      cache_options  = options.extract!(:cache_path, :expires_in).merge(:store_options => options)
      cache_filter_class = options.delete(:lock) ? DogPileFilter : SimpleFilter
      self.cache_filter = cache_filter_class.new cache_options

      around_filter self.cache_filter, options
    end

    def skip_super_caches_page(*pages)
      return unless self.cache_filter
      options = pages.extract_options!
      options[:only] = (Array(options[:only]) + pages).flatten
      skip_around_filter self.cache_filter, options
>>>>>>> something
    end
  end
end

ActionController::Base.__send__ :include, SuperCache
