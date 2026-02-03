"""
Simple in-memory cache for shared hosting (no Redis required).
Thread-safe with TTL support.
"""
import time
import threading
from functools import wraps
import hashlib
import json

class SimpleCache:
    """Thread-safe in-memory cache with TTL."""
    
    def __init__(self):
        self._cache = {}  # key -> (value, expire_time)
        self._lock = threading.Lock()
    
    def get(self, key):
        """Get value from cache. Returns None if expired or not found."""
        with self._lock:
            if key in self._cache:
                value, expire_time = self._cache[key]
                if expire_time > time.time():
                    return value
                else:
                    # Expired, remove it
                    del self._cache[key]
            return None
    
    def set(self, key, value, ttl_seconds=60):
        """Set value in cache with TTL."""
        with self._lock:
            expire_time = time.time() + ttl_seconds
            self._cache[key] = (value, expire_time)
    
    def delete(self, key):
        """Delete a specific key from cache."""
        with self._lock:
            self._cache.pop(key, None)
    
    def delete_pattern(self, pattern):
        """Delete all keys matching a pattern (simple prefix match)."""
        with self._lock:
            keys_to_delete = [k for k in self._cache.keys() if k.startswith(pattern)]
            for key in keys_to_delete:
                del self._cache[key]
    
    def clear(self):
        """Clear all cache."""
        with self._lock:
            self._cache.clear()
    
    def cleanup_expired(self):
        """Remove all expired entries. Call periodically."""
        now = time.time()
        with self._lock:
            expired = [k for k, (v, exp) in self._cache.items() if exp <= now]
            for key in expired:
                del self._cache[key]
            return len(expired)
    
    def stats(self):
        """Get cache statistics."""
        with self._lock:
            now = time.time()
            total = len(self._cache)
            active = sum(1 for k, (v, exp) in self._cache.items() if exp > now)
            return {"total_keys": total, "active_keys": active, "expired_keys": total - active}


# Global cache instance
cache = SimpleCache()


def cached(ttl_seconds=60, key_prefix=""):
    """
    Decorator to cache function results.
    
    Usage:
        @cached(ttl_seconds=300, key_prefix="discover")
        def get_discover_data(page, limit):
            ...
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Build cache key from function name and arguments
            key_parts = [key_prefix or func.__name__]
            key_parts.extend(str(a) for a in args)
            key_parts.extend(f"{k}={v}" for k, v in sorted(kwargs.items()))
            cache_key = ":".join(key_parts)
            
            # Check cache first
            cached_value = cache.get(cache_key)
            if cached_value is not None:
                return cached_value
            
            # Call function and cache result
            result = func(*args, **kwargs)
            cache.set(cache_key, result, ttl_seconds)
            return result
        
        return wrapper
    return decorator


def cache_key_for_user(prefix, user_id, *args):
    """Generate a cache key for user-specific data."""
    parts = [prefix, f"user:{user_id}"]
    parts.extend(str(a) for a in args)
    return ":".join(parts)


def invalidate_user_cache(user_id):
    """Invalidate all cache entries for a specific user."""
    # Invalidate all user-specific cache keys
    cache.delete_pattern(f"discover:{user_id}")
    cache.delete_pattern(f"library:{user_id}")
    cache.delete_pattern(f"sub:{user_id}")
    cache.delete_pattern(f"playlist:{user_id}")


# Cache TTL constants (in seconds)
CACHE_TTL_LONG = 300      # 5 minutes - for static data like categories
CACHE_TTL_MEDIUM = 60     # 1 minute - for semi-static data
CACHE_TTL_SHORT = 15      # 15 seconds - for frequently changing data
