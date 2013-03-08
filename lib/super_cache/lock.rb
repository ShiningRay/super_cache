module SuperCache
  class Lock
    class MaxRetriesError < RuntimeError; end

    DEFAULT_RETRY = 5
    DEFAULT_EXPIRY = 30
    
    class << self
      def synchronize(key, lock_expiry = DEFAULT_EXPIRY, retries = DEFAULT_RETRY)
        if recursive_lock?(key)
          yield
        else
          begin
            retries.times do |count|
              return yield if acquire_lock(key, lock_expiry)
              raise MaxRetriesError if count == retries - 1
              exponential_sleep(count) unless count == retries - 1
            end
            raise MaxRetriesError, "Couldn't acquire memcache lock for: #{key}"      
          ensure
            release_lock(key)
          end
        end
      end

      def acquire_lock(key, lock_expiry = DEFAULT_EXPIRY)
        Rails.cache.write("lock/#{key}", Process.pid, :unless_exist => true, :expires_in => lock_expiry)
      end

      def release_lock(key)
        Rails.cache.delete("lock/#{key}")
      end

      def exponential_sleep(count)
        Benchmark::measure { sleep((2**count) / 5.0) }
      end

      private
      def recursive_lock?(key)
        Rails.cache.read("lock/#{key}") == Process.pid
      end
    end
  end
end