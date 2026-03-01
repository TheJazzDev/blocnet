"""
Abstract base classes for LLM providers.

This module defines the interface that all LLM providers must implement,
enabling plug-and-play model swapping with automatic fallback.
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field


class AnalysisResult(BaseModel):
    """Result from content analysis."""

    quality: float = Field(..., ge=0.0, le=1.0, description="Overall quality score 0-1")
    sentiment: str = Field(..., description="positive|neutral|negative")
    topics: List[str] = Field(default_factory=list, description="Detected topics")
    urgency_justification: str = Field(..., description="Why this is urgent or not")
    actionability: float = Field(..., ge=0.0, le=1.0, description="How actionable 0-1")
    key_insights: List[str] = Field(default_factory=list, description="Key takeaways")
    web_context_used: bool = Field(default=False, description="Whether web search was used")


class EmbeddingResult(BaseModel):
    """Result from embedding generation."""

    embedding: List[float] = Field(..., description="Vector embedding")
    model: str = Field(..., description="Model name used")
    dimensions: int = Field(..., description="Embedding dimensions")


class LLMProvider(ABC):
    """
    Abstract base class for all LLM providers.

    Providers must implement content analysis, embedding generation,
    and availability checks to participate in the provider registry.
    """

    def __init__(self, config: Dict[str, Any]):
        """
        Initialize provider with configuration.

        Args:
            config: Configuration dictionary containing API keys, URLs, etc.
        """
        self.config = config
        self.name = self.__class__.__name__.replace('Provider', '').lower()
        self.last_availability_error: Optional[str] = None

    @abstractmethod
    async def analyze_content(
        self,
        content: str,
        context: Optional[Dict] = None
    ) -> AnalysisResult:
        """
        Analyze content and return structured insights.

        Args:
            content: Text content to analyze (update text)
            context: Optional additional context (web data, user prefs, etc.)

        Returns:
            AnalysisResult with quality, sentiment, topics, etc.
        """
        pass

    @abstractmethod
    async def generate_embedding(
        self,
        text: str
    ) -> EmbeddingResult:
        """
        Generate vector embedding for text.

        Args:
            text: Text to embed

        Returns:
            EmbeddingResult with vector and metadata
        """
        pass

    @abstractmethod
    async def is_available(self) -> bool:
        """
        Check if provider is available and configured.

        Returns:
            True if provider can be used, False otherwise
        """
        pass

    @property
    @abstractmethod
    def supports_web_search(self) -> bool:
        """
        Whether this provider can search the web for context.

        Returns:
            True if provider supports web grounding/search
        """
        pass

    def __str__(self) -> str:
        return f"{self.name}Provider"

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__} available={self.is_available()}>"
