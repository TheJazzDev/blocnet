"""Content analysis endpoint."""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional, Dict, List
import logging

from ..models.registry import ProviderRegistry
from ..models.base import AnalysisResult
from ..config import get_settings

logger = logging.getLogger(__name__)

router = APIRouter()


class AnalyzeRequest(BaseModel):
    """Request model for content analysis."""

    content: str = Field(..., description="Update content to analyze", max_length=10000)
    context: Optional[Dict] = Field(None, description="Additional context (web data, user prefs)")
    require_web_search: bool = Field(False, description="Whether to use web search for analysis")
    provider: Optional[str] = Field(None, description="Specific provider to use (optional)")


class AnalyzeResponse(BaseModel):
    """Response model for content analysis."""

    analysis: AnalysisResult
    provider_used: str
    cached: bool = False


# Global registry instance
_registry: Optional[ProviderRegistry] = None


def get_registry() -> ProviderRegistry:
    """Get or create provider registry."""
    global _registry
    if _registry is None:
        settings = get_settings()
        _registry = ProviderRegistry(settings.to_dict())
    return _registry


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_content(
    request: AnalyzeRequest,
    registry: ProviderRegistry = Depends(get_registry)
) -> AnalyzeResponse:
    """
    Analyze crypto update content.

    Uses LLM to analyze quality, sentiment, topics, actionability, and insights.
    Automatically falls back to next provider if primary fails.

    Args:
        request: Analysis request with content and optional context

    Returns:
        Analysis result with provider info

    Raises:
        HTTPException: If all providers fail
    """

    try:
        logger.info(f"Analyzing content ({len(request.content)} chars)")

        if request.provider:
            # Use specific provider
            provider = await registry.get_provider(request.provider)
            if not provider:
                reason = registry.get_unavailability_reason(request.provider)
                detail = f"Provider '{request.provider}' not available"
                if reason:
                    detail = f"{detail}: {reason}"
                raise HTTPException(
                    status_code=400,
                    detail=detail
                )

            result = await provider.analyze_content(
                content=request.content,
                context=request.context
            )
            provider_used = request.provider

        else:
            # Use automatic fallback
            result = await registry.analyze_with_fallback(
                content=request.content,
                context=request.context,
                require_web_search=request.require_web_search
            )

            # Determine which provider was used
            provider = await registry.get_available_provider(
                require_web_search=request.require_web_search
            )
            provider_used = provider.name if provider else "unknown"

        return AnalyzeResponse(
            analysis=result,
            provider_used=provider_used,
            cached=False
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Analysis failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Analysis failed: {str(e)}"
        )


@router.post("/analyze/batch", response_model=List[AnalyzeResponse])
async def analyze_batch(
    requests: List[AnalyzeRequest],
    registry: ProviderRegistry = Depends(get_registry)
) -> List[AnalyzeResponse]:
    """
    Analyze multiple updates in batch.

    Args:
        requests: List of analysis requests

    Returns:
        List of analysis results

    Raises:
        HTTPException: If batch processing fails
    """

    if len(requests) > 50:
        raise HTTPException(
            status_code=400,
            detail="Batch size too large (max 50)"
        )

    results = []

    for req in requests:
        try:
            result = await analyze_content(req, registry)
            results.append(result)
        except Exception as e:
            logger.error(f"Batch item failed: {e}")
            # Return error for this item but continue
            results.append(AnalyzeResponse(
                analysis=AnalysisResult(
                    quality=0.0,
                    sentiment="neutral",
                    topics=[],
                    urgency_justification=f"Analysis failed: {str(e)}",
                    actionability=0.0,
                    key_insights=[],
                    web_context_used=False
                ),
                provider_used="error",
                cached=False
            ))

    return results
