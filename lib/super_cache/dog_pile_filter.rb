module SuperCache
  class DogPileFilter
    attr_accessor :options
    def initialize(options={})
      self.options = options
    end
    # 1. check the expiration info of target key
    # 2. if target key is expired, add a lock against target key
    # 2.1 if not expired, return the cache
    # 3.1 if lock successfully, then continue to action 
    # 3.2 if lock failed, then obtain target key
    # 3.2.1 if target key is missing, then
    # 3.2.1.1  wait for N sec to check if the cache is generated
    # 3.2.1.1.1 if timeout, go to action
    # 3.2.2 target key is not missing, return the cache
    # 3.3 go to the action and obtain response body
    # 3.4 store the response body to the target key and set the expiration with 2x longer
    # 3.5 store the expireation info of target key
    def filter(controller, action=nil, &block)
      action ||= block
      return action.call unless controller.perform_caching
      options = self.options.dup

      options[:controller] = controller
      options[:action] = action || block
      options[:cache_path] ||= controller.instance_variable_get('@caches_path') || controller.request.fullpath
      options[:flag_key] = "expires_at:#{options[:cache_path]}"
      options[:expires_in] ||= 600
      options[:content] = nil

      if Rails.cache.read(options[:flag_key], :raw => true) 
        check_cache(options)
      else
        cache_expired(options)
      end
    end

    protected
    def write_cache(options)
      response = options[:controller].response
      return if response.status.to_i != 200
      expires_in = options[:expires_in].to_i
      Rails.cache.write(options[:flag_key], expires_in, :raw => true, :expires_in => expires_in)
      Rails.cache.write(options[:cache_path], response.body, :raw => true, :expires_in => expires_in * 2)      
    end

    def check_cache(options)
      if options[:content] = Rails.cache.read(options[:cache_path], :raw => true) and options[:content].size > 0
        cache_hit(options)
      else
        cache_miss(options)
      end             
    end    

    def cache_hit(options)
      controller = options[:controller]
      request = controller.request
      headers = controller.headers
      content = options[:content]
      Rails.logger.info "Hit #{options[:cache_path]}"
      headers['Content-Length'] ||= content.size.to_s
      headers['Content-Type'] ||= request.format.to_s.strip unless  request.format == :all
      controller.send :render, :text => content, :content_type => 'text/html'
    end

    #when the target cache is not established yet
    def cache_miss(options)
      Lock.synchronize(options[:cache_path]) do
        options[:action].call
        write_cache(options)
      end
    rescue Lock::MaxRetriesError
      options[:action].call
      write_cache(options)
    end

    # the cache is expired
    def cache_expired(options) 
      if Lock.acquire_lock(options[:cache_path])
        options[:action].call
        write_cache(options)
      else
        # haven't acquired lock, return stale cache
        check_cache(options)
      end
    end    
  end
end