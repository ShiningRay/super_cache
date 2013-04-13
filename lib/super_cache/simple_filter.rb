module SuperCache
  class SimpleFilter
    def self.filter(options, controller, action)
      if controller.perform_caching
        new(options, controller, action).filter
      else
        action.call
      end
    end
    attr_accessor :options, :controller, :action, :cache_path, :content_type, :response, :request
    # Public
    # canonical_path (calc path using current params)
    #
    def initialize(options, controller, action)
      self.options = options
      self.controller = controller
      self.action = action
      self.request = controller.request
      self.response = controller.response      
      path, use_canonical_path = options.extract!(:cache_path, :use_canonical_path)
      
      path_options = if path.respond_to?(:call)
        controller.instance_exec(controller, &path)
      else
        path || request.fullpath
      end
      #
      if use_canonical_path || !path.is_a?(String)
        path = ActionController::Caching::Actions::ActionCachePath.new(controller, path_options || {})
        self.cache_path = path.path
        self.content_type = Mime[path.extension || :html]
      else
        self.cache_path = path
        self.content_type = request.format.to_s.in?('', '*/*') ? Mime[:html] : request.format
      end
    end

    def filter
      if content = Rails.cache.read(cache_path, :raw => true)
        cache_hit(content)
      else
        cache_miss
      end
    end  
    alias check_cache filter
    if Gem.loaded_spec['rails'].version >= '3.0'
      def cache_hit(content)
        Rails.logger.info "Hit #{cache_path}"
        controller.response_body = content
        controller.content_type = self.content_type
      end
    else
      def cache_hit(content)
        Rails.logger.info "Hit #{cache_path}"
        controller.send :render, :text => content, :content_type =>  content_type
      end      
    end


    def cache_miss
      action.call
      write_cache if response.status.to_i == 200
    end
    alias pass cache_miss

    def write_cache
      Rails.logger.info "Write #{cache_path}"
      Rails.cache.write(cache_path, response.body, :raw => true, :expires_in => options[:expires_in])
    end      
  end
end