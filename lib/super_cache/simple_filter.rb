module SuperCache
  class SimpleFilter
    attr_accessor :options
    # Public
    # canonical_path (calc path using current params)
    #
    def initialize(options={})
      self.options = options
    end

    def filter(controller)
      return yield unless controller.perform_caching
      @cache_path = controller.instance_variable_get('@caches_path') || controller.request.fullpath
      request = controller.request
      response = controller.response
      headers = response.headers

      if content = Rails.cache.read(@cache_path, :raw => true)
        return yield if content.size <= 0
        Rails.logger.debug "Hit #{@cache_path}"
        headers['Content-Length'] ||= content.size.to_s
        headers['Content-Type'] ||= request.format.to_s.strip unless  request.format == :all
        controller.send :render, :text => content, :content_type => 'text/html'
        return false
      else
        yield
        body = response.body.to_s
        return if controller.instance_variable_get('@no_cache') || body.size == 0 || response.status.to_i != 200        
        @expires_in = controller.instance_variable_get('@expires_in') || 600 
        Rails.logger.debug("Write #{@cache_path}")
        Rails.cache.write(@cache_path, body, :raw => true, :expires_in => @expires_in.to_i)            
      end
    rescue ArgumentError => e
      @no_cache = true
      Rails.logger.info e.to_s
      Rails.logger.debug {e.backtrace}
    end
  end
end