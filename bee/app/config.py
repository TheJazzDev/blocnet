"""
Configuration management for BEE ML service.

Loads configuration from environment variables with sensible defaults.
"""

import os
from functools import lru_cache
from typing import Optional


class Settings:
    """Application settings loaded from environment."""

    # Server settings
    HOST: str = os.getenv('HOST', '0.0.0.0')
    PORT: int = int(os.getenv('PORT', '8083'))
    ENVIRONMENT: str = os.getenv('ENVIRONMENT', 'development')
    LOG_LEVEL: str = os.getenv('LOG_LEVEL', 'INFO')

    # Provider priority (comma-separated)
    PROVIDER_PRIORITY: str = os.getenv('PROVIDER_PRIORITY', 'ollama,groq,gemini')

    # Ollama settings (local)
    ENABLE_OLLAMA: bool = os.getenv('ENABLE_OLLAMA', 'true').lower() == 'true'
    OLLAMA_URL: str = os.getenv('OLLAMA_URL', 'http://localhost:11434')
    OLLAMA_MODEL: str = os.getenv('OLLAMA_MODEL', 'llama3.3:70b')
    OLLAMA_EMBEDDING_MODEL: str = os.getenv('OLLAMA_EMBEDDING_MODEL', 'nomic-embed-text')
    OLLAMA_TIMEOUT: float = float(os.getenv('OLLAMA_TIMEOUT', '120.0'))

    # Groq settings (free cloud)
    GROQ_API_KEY: Optional[str] = os.getenv('GROQ_API_KEY')
    GROQ_MODEL: str = os.getenv('GROQ_MODEL', 'llama-3.3-70b-versatile')

    # Gemini settings (free cloud with search)
    GEMINI_API_KEY: Optional[str] = os.getenv('GEMINI_API_KEY')
    GEMINI_MODEL: str = os.getenv('GEMINI_MODEL', 'gemini-2.0-flash-exp')
    GEMINI_EMBEDDING_MODEL: str = os.getenv('GEMINI_EMBEDDING_MODEL', 'models/text-embedding-004')

    # OpenAI settings (optional, paid)
    OPENAI_API_KEY: Optional[str] = os.getenv('OPENAI_API_KEY')
    OPENAI_MODEL: str = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')

    # Redis settings (optional caching)
    REDIS_URL: Optional[str] = os.getenv('REDIS_URL')
    CACHE_TTL: int = int(os.getenv('CACHE_TTL', '86400'))  # 24 hours

    # CORS settings
    CORS_ORIGINS: str = os.getenv('CORS_ORIGINS', 'http://localhost:3080,http://localhost:3081')

    # API settings
    MAX_CONTENT_LENGTH: int = int(os.getenv('MAX_CONTENT_LENGTH', '10000'))  # chars

    def to_dict(self) -> dict:
        """Convert settings to dictionary for provider initialization."""
        return {
            'provider_priority': self.PROVIDER_PRIORITY,
            'enable_ollama': self.ENABLE_OLLAMA,
            'ollama_url': self.OLLAMA_URL,
            'ollama_model': self.OLLAMA_MODEL,
            'ollama_embedding_model': self.OLLAMA_EMBEDDING_MODEL,
            'ollama_timeout': self.OLLAMA_TIMEOUT,
            'groq_api_key': self.GROQ_API_KEY,
            'groq_model': self.GROQ_MODEL,
            'gemini_api_key': self.GEMINI_API_KEY,
            'gemini_model': self.GEMINI_MODEL,
            'gemini_embedding_model': self.GEMINI_EMBEDDING_MODEL,
            'openai_api_key': self.OPENAI_API_KEY,
            'openai_model': self.OPENAI_MODEL,
            'redis_url': self.REDIS_URL,
            'cache_ttl': self.CACHE_TTL,
        }


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
