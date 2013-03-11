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
      return unless perform_caching
      options = pages.extract_options!
      options[:only] = (Array(options[:only]) + pages).flatten
      cache_filter_class = options.delete(:lock) ? DogPileFilter : SimpleFilter
      self.cache_filter = cache_filter_class.new cache_options
      around_filter self.cache_filter, options
    end

    def skip_super_caches_page(*pages)
      return unless self.cache_filter
      options = pages.extract_options!
      options[:only] = (Array(options[:only]) + pages).flatten
      skip_around_filter self.cache_filter, options
    end
  end
end

ActionController::Base.__send__ :include, SuperCache
