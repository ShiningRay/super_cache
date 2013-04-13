module SuperCache
	module CacheMetaInfo
		module RedisStore
			def append_cached_key(key)
			  cached_keys << key
			end
			def clear_related_caches
				cached_keys.each do |key|
					Rails.cache.delete key
					cached_keys.delete key
				end
			end
			
		    def remove_cached_key(key)
		      cached_keys.delete key
		    end

			def self.included(base)
				base.class_eval do
					include ::Redis::Objects unless included_modules.include?(::Redis::Objects)
					set :cached_keys
				end
			end
		end
	end
end
