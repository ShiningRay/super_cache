module SuperCache
  class SimpleFilter
    def initialize(options={})
      
    end

    def filter(controller)
      return yield unless controller.perform_caching
      @cache_path = controller.instance_variable_get('@caches_path') || weird_cache_path(controller)
      request = controller.request
      response = controller.response
      headers = response.headers
      if content = Rails.cache.read(@cache_path, :raw => true)
        return yield if content.size <= 0
        Rails.logger.info "Hit #{@cache_path}"
        headers['Content-Length'] ||= content.size.to_s
        headers['Content-Type'] ||= request.format.to_s.strip unless  request.format == :all
        controller.send :render, :text => content, :content_type => 'text/html'
        return false
      else
        yield
        return if controller.instance_variable_get('@no_cache') || response.body.size == 0 || response.status.to_i != 200        
        @expires_in = controller.instance_variable_get('@expires_in') || 600 
        Rails.cache.write(@cache_path, response.body, :raw => true, :expires_in => @expires_in.to_i)            
      end
    rescue ArgumentError => e
      @no_cache = true
      Rails.logger.info e.to_s
      Rails.logger.debug {e.backtrace}
    end

    private
      def weird_cache_path(controller)
        controller.instance_eval do
          path = File.join request.host, request.path
          q = request.query_string
          request.format ||= :html
          format = request.format.to_sym
          path = "#{path}.#{format}" if format != :html and format != :all and params[:format].blank?
          path = "#{path}?#{q}" if !q.empty? && q =~ /=/
          path          
        end
      end    
  end
end