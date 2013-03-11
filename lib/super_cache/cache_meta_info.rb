# To change this template, choose Tools | Templates
# and open the template in the editor.
module SuperCache
  module CacheMetaInfo
    autoload RedisStore
    autoload MemCacheStore

    def key_for_cached_keys
      "#{self.class.name}:#{self.id}:cached_keys"
    end

    def clear_related_caches
      Rails.cache.debug{cached_keys.to_a.join(' ')}
      cached_keys.each do |key|
        Rails.cache.delete key
      end
      clear_cached_keys
    end

    def remove_cached_key(key)
      c = cached_keys.unique
      k = c.delete(key)
      Rails.cache.write key_for_cached_keys, c.join(','), :raw => true
      k
    end

    def each_cached_key
      cache_keys.each do |key|
        yield key
      end
    end

    def cached_keys
      @cached_keys ||= begin
        c = Rails.cache.read(key_for_cached_keys, :raw => true)
        c.blank? ? [] : c.split(/,/)
      end
    end

    def clear_cached_keys
      Rails.cache.delete key_for_cached_keys
    end
  end
end
