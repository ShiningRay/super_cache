require "super_cache/version"
require 'uri'
require 'fileutils'
# for static-caching the generated html pages

module SuperCache
  autoload :Lock, 'super_cache/lock'
  autoload :DogPileFilter, 'super_cache/dog_pile_filter'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def super_caches_page(*pages)
      return unless perform_caching
      options = pages.extract_options!
      options[:only] = (Array(options[:only]) + pages).flatten
      if options.delete(:lock)
        around_filter DogPileFilter.new
      else
        before_filter :check_weird_cache, options
        after_filter :weird_cache, options
      end
    end

    def skip_super_caches_page(*pages)
      options = pages.extract_options!
      options[:only] = (Array(options[:only]) + pages).flatten
      skip_before_filter :check_weird_cache, options
      skip_before_filter :check_weird_cache_with_lock, options
      skip_after_filter :weird_cache, options
    end
  end

  def check_weird_cache
    return unless perform_caching
    @cache_path ||= weird_cache_path
    
    if content = Rails.cache.read(@cache_path, :raw => true)
      return if content.size <= 0
      logger.info "Hit #{@cache_path}"

      headers['Content-Length'] ||= content.size.to_s
      headers['Content-Type'] ||= request.format.to_s.strip unless  request.format == :all
      render :text => content, :content_type => 'text/html'
      return false
    end
  rescue ArgumentError => e
    @no_cache = true
    logger.info e.to_s
    logger.debug {e.backtrace}
  end

  def weird_cache
    return if @no_cache
    return unless perform_caching
    return if request.format.to_sym == :mobile
    @cache_path ||= weird_cache_path
    @expires_in ||= 600
    #return if response.body.size <= 1
    return if response.status.to_i != 200
    #benchmark "Super Cached page: #{@cache_path}" do
    #  @cache_subject = Array(@cache_subject)
    #  @cache_subject.compact.flatten.select{|s|s.respond_to?(:append_cached_key)}.each do |subject|
    #    subject.append_cached_key @cache_path
    #  end
    Rails.cache.write(@cache_path, response.body, :raw => true, :expires_in => @expires_in.to_i)
    #end
  end

  protected :check_weird_cache
  protected :weird_cache
  private
    def weird_cache_path
      path = File.join request.host, request.path
      q = request.query_string
      request.format ||= :html
      format = request.format.to_sym
      path = "#{path}.#{format}" if format != :html and format != :all and params[:format].blank?
      path = "#{path}?#{q}" if !q.empty? && q =~ /=/
      path
    end
end

ActionController::Base.__send__ :include, SuperCache
