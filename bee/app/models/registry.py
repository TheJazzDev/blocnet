"""
Provider registry with automatic fallback.

Manages multiple LLM providers with configurable priority ordering.
Automatically falls back to next provider if primary is unavailable.
"""

from typing import Dict, List, Optional
import logging
import time
from .base import LLMProvider, AnalysisResult, EmbeddingResult
from .providers.ollama import OllamaProvider
from .providers.groq import GroqProvider
from .providers.gemini import GeminiProvider

logger = logging.getLogger(__name__)


class ProviderRegistry:
    """Manages multiple LLM providers with automatic fallback."""

    def __init__(self, config: Dict):
        """
        Initialize provider registry.

        Args:
            config: Configuration dictionary with provider settings
        """
        self.config = config
        self.providers: Dict[str, LLMProvider] = {}
        self.priority_order: List[str] = []
        self._availability_cache: Dict[str, bool] = {}
        self._availability_cache_at: Dict[str, float] = {}
        self._availability_reasons: Dict[str, Optional[str]] = {}
        self._availability_cache_ttl_seconds = 60.0

        self._initialize_providers()

    def _initialize_providers(self):
        """Initialize all configured providers."""

        # Ollama (local)
        if self.config.get('enable_ollama', True):
            try:
                self.providers['ollama'] = OllamaProvider(self.config)
                logger.info("Initialized Ollama provider")
            except Exception as e:
                logger.warning(f"Failed to initialize Ollama provider: {e}")

        # Groq (free cloud)
        if self.config.get('groq_api_key'):
            try:
                self.providers['groq'] = GroqProvider(self.config)
                logger.info("Initialized Groq provider")
            except Exception as e:
                logger.warning(f"Failed to initialize Groq provider: {e}")

        # Gemini (free cloud with search)
        if self.config.get('gemini_api_key'):
            try:
                self.providers['gemini'] = GeminiProvider(self.config)
                logger.info("Initialized Gemini provider")
            except Exception as e:
                logger.warning(f"Failed to initialize Gemini provider: {e}")

        # Define priority order (user configurable)
        default_priority = ['ollama', 'groq', 'gemini']
        priority_str = self.config.get('provider_priority', '')

        if priority_str:
            # Parse comma-separated priority string
            self.priority_order = [p.strip() for p in priority_str.split(',')]
        else:
            self.priority_order = default_priority

        # Filter to only include initialized providers
        self.priority_order = [
            p for p in self.priority_order
            if p in self.providers
        ]

        logger.info(f"Provider priority order: {self.priority_order}")
        logger.info(f"Available providers: {list(self.providers.keys())}")

    async def get_available_provider(
        self,
        require_web_search: bool = False
    ) -> Optional[LLMProvider]:
        """
        Get first available provider based on priority.

        Args:
            require_web_search: If True, only return providers with web search

        Returns:
            First available provider or None
        """

        for provider_name in self.priority_order:
            provider = self.providers.get(provider_name)

            if not provider:
                continue

            # Check if available (with caching)
            available = await self._check_availability(provider_name, provider)

            if not available:
                reason = self.get_unavailability_reason(provider_name)
                if reason:
                    logger.debug(f"Provider {provider_name} not available: {reason}")
                else:
                    logger.debug(f"Provider {provider_name} not available")
                continue

            # Check if web search required
            if require_web_search and not provider.supports_web_search:
                logger.debug(f"Provider {provider_name} doesn't support web search")
                continue

            logger.info(f"Selected provider: {provider_name}")
            return provider

        logger.warning("No available providers found")
        return None

    async def get_provider(self, name: str) -> Optional[LLMProvider]:
        """
        Get specific provider by name.

        Args:
            name: Provider name (ollama, groq, gemini)

        Returns:
            Provider instance or None if unavailable
        """

        provider = self.providers.get(name)

        if not provider:
            logger.warning(f"Provider {name} not found")
            return None

        available = await self._check_availability(name, provider)

        if not available:
            reason = self.get_unavailability_reason(name)
            if reason:
                logger.warning(f"Provider {name} not available: {reason}")
            else:
                logger.warning(f"Provider {name} not available")
            return None

        return provider

    async def analyze_with_fallback(
        self,
        content: str,
        context: Optional[Dict] = None,
        require_web_search: bool = False
    ) -> AnalysisResult:
        """
        Analyze content with automatic provider fallback.

        Tries providers in priority order until one succeeds.

        Args:
            content: Content to analyze
            context: Optional context data
            require_web_search: Whether web search is required

        Returns:
            AnalysisResult from first successful provider

        Raises:
            Exception if all providers fail
        """

        errors = []

        for provider_name in self.priority_order:
            provider = self.providers.get(provider_name)

            if not provider:
                errors.append(f"{provider_name} not configured")
                continue

            available = await self._check_availability(provider_name, provider)
            if not available:
                reason = self.get_unavailability_reason(provider_name) or "unavailable"
                errors.append(f"{provider_name} unavailable: {reason}")
                continue

            # Skip if web search required but not supported
            if require_web_search and not provider.supports_web_search:
                errors.append(f"{provider_name} does not support web search")
                continue

            try:
                logger.info(f"Analyzing with {provider_name}...")
                result = await provider.analyze_content(content, context)
                logger.info(f"Analysis successful with {provider_name}")
                return result

            except Exception as e:
                error_msg = f"{provider_name} failed: {str(e)}"
                logger.warning(error_msg)
                errors.append(error_msg)
                # Continue to next provider
                continue

        # All providers failed
        error_summary = "; ".join(errors)
        raise Exception(f"All providers failed: {error_summary}")

    async def embed_with_fallback(
        self,
        text: str
    ) -> EmbeddingResult:
        """
        Generate embedding with automatic provider fallback.

        Args:
            text: Text to embed

        Returns:
            EmbeddingResult from first successful provider

        Raises:
            Exception if all providers fail
        """

        errors = []

        for provider_name in self.priority_order:
            provider = self.providers.get(provider_name)

            if not provider:
                errors.append(f"{provider_name} not configured")
                continue

            available = await self._check_availability(provider_name, provider)
            if not available:
                reason = self.get_unavailability_reason(provider_name) or "unavailable"
                errors.append(f"{provider_name} unavailable: {reason}")
                continue

            try:
                logger.info(f"Generating embedding with {provider_name}...")
                result = await provider.generate_embedding(text)
                logger.info(f"Embedding successful with {provider_name}")
                return result

            except Exception as e:
                error_msg = f"{provider_name} failed: {str(e)}"
                logger.warning(error_msg)
                errors.append(error_msg)
                continue

        # All providers failed
        error_summary = "; ".join(errors)
        raise Exception(f"All providers failed for embedding: {error_summary}")

    async def list_available_providers(self) -> List[Dict[str, any]]:
        """
        List all available providers with their status.

        Returns:
            List of provider info dicts
        """

        result = []

        for name, provider in self.providers.items():
            available = await self._check_availability(name, provider)

            result.append({
                'name': name,
                'available': available,
                'reason': None if available else self.get_unavailability_reason(name),
                'supports_web_search': provider.supports_web_search,
                'priority': self.priority_order.index(name) if name in self.priority_order else -1
            })

        return sorted(result, key=lambda x: x['priority'] if x['priority'] >= 0 else 999)

    async def _check_availability(
        self,
        name: str,
        provider: LLMProvider
    ) -> bool:
        """
        Check provider availability with caching.

        Caches availability for 60 seconds to avoid excessive checks.

        Args:
            name: Provider name
            provider: Provider instance

        Returns:
            True if available
        """

        # Check cache first
        cached = self._availability_cache.get(name)
        cached_at = self._availability_cache_at.get(name, 0.0)
        if cached is not None and (time.time() - cached_at) < self._availability_cache_ttl_seconds:
            return self._availability_cache[name]

        # Check actual availability
        try:
            available = await provider.is_available()
            self._availability_cache[name] = available
            self._availability_cache_at[name] = time.time()
            self._availability_reasons[name] = (
                None if available else provider.last_availability_error
            )

            # Clear cache after 60 seconds (could use redis or TTL cache)
            # For now, simple in-memory cache

            return available

        except Exception as e:
            self._availability_reasons[name] = f"Availability check error: {str(e)}"
            logger.error(f"Error checking {name} availability: {e}")
            return False

    def get_unavailability_reason(self, name: str) -> Optional[str]:
        """Get the latest known unavailability reason for a provider."""
        return self._availability_reasons.get(name)

    def clear_availability_cache(self):
        """Clear the availability cache to force fresh checks."""
        self._availability_cache.clear()
        self._availability_cache_at.clear()
        self._availability_reasons.clear()
        logger.info("Availability cache cleared")
