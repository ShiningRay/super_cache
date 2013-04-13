require "super_cache/version"
require 'uri'
require 'fileutils'
require 'super_cache/mem_cache_store_patch'

# for static-caching the generated html pages
module SuperCache
  autoload :Lock,          'super_cache/lock'
  autoload :DogPileFilter, 'super_cache/dog_pile_filter'
  autoload :SimpleFilter,  'super_cache/simple_filter'
  autoload :CacheMetaInfo, 'super_cache/cache_meta_info'
  def self.included(base)
    base.class_attribute :cache_filter
    base.extend(ClassMethods)
  end

  module ClassMethods
    def super_caches_page(*pages)
      return unless perform_caching
      options = pages.extract_options!
      filter_options = options.extract!(:if, :unless)
      filter_options[:only] = (Array(options[:only]) + pages).flatten
      cache_filter_class = options.delete(:lock) ? DogPileFilter : SimpleFilter
      around_filter filter_options do |controller, action|
        cache_filter_class.filter(options.dup, controller, action)
      end
    end
  end
end

ActionController::Base.__send__ :include, SuperCache
