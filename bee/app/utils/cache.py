"""
Caching utilities for BEE ML service.

Provides simple in-memory caching with optional Redis backend.
Caches LLM responses to reduce API calls and improve performance.
"""

import json
import hashlib
from typing import Optional, Any
from functools import lru_cache
import logging

logger = logging.getLogger(__name__)


class Cache:
    """Simple cache with in-memory or Redis backend."""

    def __init__(self, redis_url: Optional[str] = None, ttl: int = 86400):
        """
        Initialize cache.

        Args:
            redis_url: Optional Redis URL for distributed caching
            ttl: Time to live in seconds (default 24 hours)
        """
        self.ttl = ttl
        self.redis_client = None

        if redis_url:
            try:
                import redis.asyncio as redis
                self.redis_client = redis.from_url(redis_url, decode_responses=True)
                logger.info(f"Redis cache initialized: {redis_url}")
            except ImportError:
                logger.warning("redis package not installed, using in-memory cache")
            except Exception as e:
                logger.warning(f"Failed to connect to Redis, using in-memory cache: {e}")

        if not self.redis_client:
            logger.info("Using in-memory cache")
            self._memory_cache = {}

    def _generate_key(self, prefix: str, data: Any) -> str:
        """
        Generate cache key from data.

        Args:
            prefix: Key prefix (e.g., 'analysis', 'embedding')
            data: Data to hash

        Returns:
            Cache key
        """
        # Create deterministic hash from data
        data_str = json.dumps(data, sort_keys=True)
        hash_value = hashlib.sha256(data_str.encode()).hexdigest()[:16]
        return f"bee:{prefix}:{hash_value}"

    async def get(self, key: str) -> Optional[Any]:
        """
        Get value from cache.

        Args:
            key: Cache key

        Returns:
            Cached value or None
        """
        try:
            if self.redis_client:
                value = await self.redis_client.get(key)
                if value:
                    return json.loads(value)
                return None
            else:
                return self._memory_cache.get(key)
        except Exception as e:
            logger.error(f"Cache get error: {e}")
            return None

    async def set(self, key: str, value: Any) -> bool:
        """
        Set value in cache.

        Args:
            key: Cache key
            value: Value to cache

        Returns:
            True if successful
        """
        try:
            if self.redis_client:
                value_str = json.dumps(value)
                await self.redis_client.setex(key, self.ttl, value_str)
                return True
            else:
                self._memory_cache[key] = value
                # Note: in-memory cache doesn't expire automatically
                # For production, use Redis or implement TTL cleanup
                return True
        except Exception as e:
            logger.error(f"Cache set error: {e}")
            return False

    async def get_or_compute(
        self,
        prefix: str,
        data: Any,
        compute_fn,
        **kwargs
    ) -> Any:
        """
        Get from cache or compute and cache.

        Args:
            prefix: Key prefix
            data: Data to use as cache key
            compute_fn: Async function to call if cache miss
            **kwargs: Arguments to pass to compute_fn

        Returns:
            Cached or computed value
        """
        key = self._generate_key(prefix, data)

        # Try cache first
        cached = await self.get(key)
        if cached is not None:
            logger.debug(f"Cache hit: {key}")
            return cached

        # Cache miss - compute
        logger.debug(f"Cache miss: {key}")
        result = await compute_fn(**kwargs)

        # Cache result
        await self.set(key, result)

        return result

    async def delete(self, key: str) -> bool:
        """
        Delete key from cache.

        Args:
            key: Cache key

        Returns:
            True if successful
        """
        try:
            if self.redis_client:
                await self.redis_client.delete(key)
                return True
            else:
                if key in self._memory_cache:
                    del self._memory_cache[key]
                return True
        except Exception as e:
            logger.error(f"Cache delete error: {e}")
            return False

    async def clear(self) -> bool:
        """
        Clear all cache entries.

        Returns:
            True if successful
        """
        try:
            if self.redis_client:
                # Delete all keys with bee: prefix
                keys = await self.redis_client.keys('bee:*')
                if keys:
                    await self.redis_client.delete(*keys)
                return True
            else:
                self._memory_cache.clear()
                return True
        except Exception as e:
            logger.error(f"Cache clear error: {e}")
            return False


# Global cache instance
_cache: Optional[Cache] = None


@lru_cache()
def get_cache(redis_url: Optional[str] = None, ttl: int = 86400) -> Cache:
    """
    Get global cache instance.

    Args:
        redis_url: Optional Redis URL
        ttl: Cache TTL in seconds

    Returns:
        Cache instance
    """
    global _cache
    if _cache is None:
        _cache = Cache(redis_url=redis_url, ttl=ttl)
    return _cache
