"""Embedding generation endpoint."""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional, List
import logging

from ..models.registry import ProviderRegistry
from ..models.base import EmbeddingResult
from ..config import get_settings

logger = logging.getLogger(__name__)

router = APIRouter()


class EmbedRequest(BaseModel):
    """Request model for embedding generation."""

    text: str = Field(..., description="Text to embed", max_length=10000)
    provider: Optional[str] = Field(None, description="Specific provider to use (optional)")


class EmbedResponse(BaseModel):
    """Response model for embedding generation."""

    embedding: EmbeddingResult
    provider_used: str
    cached: bool = False


# Use same registry instance from analyze
def get_registry() -> ProviderRegistry:
    """Get or create provider registry."""
    from .analyze import get_registry as get_analyze_registry
    return get_analyze_registry()


@router.post("/embed", response_model=EmbedResponse)
async def generate_embedding(
    request: EmbedRequest,
    registry: ProviderRegistry = Depends(get_registry)
) -> EmbedResponse:
    """
    Generate vector embedding for text.

    Uses LLM embedding models to generate semantic vectors.
    Useful for similarity search and clustering.

    Args:
        request: Embedding request with text

    Returns:
        Embedding result with provider info

    Raises:
        HTTPException: If all providers fail
    """

    try:
        logger.info(f"Generating embedding ({len(request.text)} chars)")

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

            result = await provider.generate_embedding(text=request.text)
            provider_used = request.provider

        else:
            # Use automatic fallback
            result = await registry.embed_with_fallback(text=request.text)

            # Determine which provider was used
            provider = await registry.get_available_provider()
            provider_used = provider.name if provider else "unknown"

        return EmbedResponse(
            embedding=result,
            provider_used=provider_used,
            cached=False
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Embedding generation failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Embedding generation failed: {str(e)}"
        )


@router.post("/embed/batch", response_model=List[EmbedResponse])
async def generate_embeddings_batch(
    requests: List[EmbedRequest],
    registry: ProviderRegistry = Depends(get_registry)
) -> List[EmbedResponse]:
    """
    Generate embeddings for multiple texts in batch.

    Args:
        requests: List of embedding requests

    Returns:
        List of embedding results

    Raises:
        HTTPException: If batch processing fails
    """

    if len(requests) > 100:
        raise HTTPException(
            status_code=400,
            detail="Batch size too large (max 100)"
        )

    results = []

    for req in requests:
        try:
            result = await generate_embedding(req, registry)
            results.append(result)
        except Exception as e:
            logger.error(f"Batch embedding failed: {e}")
            raise HTTPException(
                status_code=500,
                detail=f"Batch embedding failed: {str(e)}"
            )

    return results
