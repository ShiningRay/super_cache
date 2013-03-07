module SuperCache
  class DogPileFilter
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
      @controller = controller
      @action = action || block
      return @action.call unless controller.perform_caching
      @cache_path ||= weird_cache_path
      @expires_at_key = "expires_at:#{@cache_path}"
      @expires_in ||= 600
      @content = nil

      if Rails.cache.read(@expires_at_key, :raw => true) 
        check_cache
      else
        cache_expired
      end
    end

    protected
    def write_cache
      return if @controller.response.status.to_i != 200
      Rails.cache.write(@expires_at_key, @expires_in.to_i, :raw => true, :expires_in => @expires_in.to_i)
      Rails.cache.write(@cache_path, @controller.response.body, :raw => true, :expires_in => @expires_in.to_i * 2)      
    end

    def check_cache
      if @content = Rails.cache.read(@cache_path, :raw => true) and @content.size > 0
        cache_hit
      else
        cache_miss
      end             
    end    

    def cache_hit 
      Rails.logger.info "Hit #{@cache_path}"
      @controller.headers['Content-Length'] ||= @content.size.to_s
      @controller.headers['Content-Type'] ||= @controller.request.format.to_s.strip unless  @controller.request.format == :all
      @controller.render :text => @content, :content_type => 'text/html'
    end

    #when the target cache is not established yet
    def cache_miss 
      Lock.synchronize(@cache_path) do
        @action.call
        write_cache
      end
    rescue Lock::MaxRetriesError
      @action.call
      write_cache
    end

    # the cache is expired
    def cache_expired 
      if Lock.acquire_lock(@cache_path)
        @action.call
        write_cache
      else
        # haven't acquired lock, return stale cache
        check_cache
      end
    end

    def weird_cache_path
      path = File.join @controller.request.host, @controller.request.path
      q = @controller.request.query_string
      @controller.request.format ||= :html
      format = @controller.request.format.to_sym
      path = "#{path}.#{format}" if format != :html and format != :all and @controller.params[:format].blank?
      path = "#{path}?#{q}" if !q.empty? && q =~ /=/
      path
    end    
  end
end