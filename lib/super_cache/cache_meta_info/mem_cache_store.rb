module CacheMetaInfo::MemCacheStore
  def append_cached_key(key)
    cached_keys
    @need_append ||= !Rails.cache.write(key_for_cached_keys, key,
            :raw => true,
            :unless_exist => true )
    if @need_append and not cached_keys.include?(key)
      cached_keys << key
      Rails.cache.append(key_for_cached_keys, ",#{key}") 
    end
  end
end