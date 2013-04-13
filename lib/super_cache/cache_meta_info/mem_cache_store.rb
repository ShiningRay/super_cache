module SuperCache
  module CacheMetaInfo
    module MemCacheStore
      def append_cached_key(key)
        cached_keys
        @need_append ||= !Rails.cache.write(key_for_cached_keys, key,
                :raw => true,
                :unless_exist => true )
        Rails.cache.append(key_for_cached_keys, ",#{key}")  if @need_append and not cached_keys.include?(key)
        cached_keys << key
      end
    end
  end
end