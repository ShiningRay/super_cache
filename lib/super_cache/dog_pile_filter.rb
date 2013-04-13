module SuperCache
  class DogPileFilter < SimpleFilter
    attr_accessor :flag_key
    def initialize(*args)
      super(*args)
      self.flag_key = "flag:#{cache_path}"
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
    def filter
      if Rails.cache.read(flag_key, :raw => true) 
        check_cache
      else
        cache_expired
      end
    end

    protected

    #when the target cache is not established yet
    def cache_miss
      Lock.synchronize(cache_path) do
        super
      end
    rescue Lock::MaxRetriesError
      super
    end

    # the cache is expired
    def cache_expired
      if Lock.acquire_lock(cache_path)
        pass
      else
        # haven't acquired lock, return stale cache
        check_cache
      end
    end    
    def write_cache
      expires_in = (options[:expires_in] || 600).to_i
      Rails.cache.write(flag_key, expires_in, :raw => true, :expires_in => expires_in)
      Rails.cache.write(cache_path, response.body, :raw => true, :expires_in => expires_in * 2)
      append_cache_key_to_subject(flag_key, cache_path)
    end
  end
end