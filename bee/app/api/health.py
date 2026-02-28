"""Health check and status endpoints."""

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import List, Dict
from datetime import datetime
import logging

from ..models.registry import ProviderRegistry
from ..config import get_settings
from .. import __version__

logger = logging.getLogger(__name__)

router = APIRouter()


class HealthResponse(BaseModel):
    """Health check response."""

    status: str
    version: str
    timestamp: str
    providers: List[Dict]


class ProviderInfo(BaseModel):
    """Provider information."""

    name: str
    available: bool
    reason: str | None = None
    supports_web_search: bool
    priority: int


# Use same registry instance
def get_registry() -> ProviderRegistry:
    """Get or create provider registry."""
    from .analyze import get_registry as get_analyze_registry
    return get_analyze_registry()


@router.get("/health", response_model=HealthResponse)
async def health_check(
    registry: ProviderRegistry = Depends(get_registry)
) -> HealthResponse:
    """
    Health check endpoint.

    Returns service status and available providers.

    Returns:
        Health check response with provider status
    """

    try:
        # Get provider status
        providers = await registry.list_available_providers()

        # Check if at least one provider is available
        has_available = any(p['available'] for p in providers)
        status = "healthy" if has_available else "degraded"

        return HealthResponse(
            status=status,
            version=__version__,
            timestamp=datetime.utcnow().isoformat(),
            providers=providers
        )

    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return HealthResponse(
            status="unhealthy",
            version=__version__,
            timestamp=datetime.utcnow().isoformat(),
            providers=[]
        )


@router.get("/providers", response_model=List[ProviderInfo])
async def list_providers(
    registry: ProviderRegistry = Depends(get_registry)
) -> List[ProviderInfo]:
    """
    List all configured providers.

    Returns:
        List of provider information
    """

    try:
        providers = await registry.list_available_providers()

        return [
            ProviderInfo(
                name=p['name'],
                available=p['available'],
                reason=p.get('reason'),
                supports_web_search=p['supports_web_search'],
                priority=p['priority']
            )
            for p in providers
        ]

    except Exception as e:
        logger.error(f"List providers failed: {e}")
        return []


@router.post("/providers/refresh")
async def refresh_providers(
    registry: ProviderRegistry = Depends(get_registry)
) -> Dict:
    """
    Refresh provider availability cache.

    Forces fresh availability checks for all providers.

    Returns:
        Refresh status
    """

    try:
        registry.clear_availability_cache()
        providers = await registry.list_available_providers()

        return {
            "status": "refreshed",
            "timestamp": datetime.utcnow().isoformat(),
            "providers": providers
        }

    except Exception as e:
        logger.error(f"Refresh providers failed: {e}")
        return {
            "status": "error",
            "error": str(e)
        }
