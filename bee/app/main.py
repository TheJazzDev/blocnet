"""
BEE ML Service - Blocnet Edge Engine Machine Learning Service.

FastAPI application providing LLM-powered content analysis and embeddings
with automatic provider fallback and caching.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging

from .config import get_settings
from .utils.logger import setup_logger
from .api import analyze, embed, health
from . import __version__

# Load settings
settings = get_settings()

# Setup logging
setup_logger(settings.LOG_LEVEL)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="BEE ML Service",
    description="Blocnet Edge Engine Machine Learning Service - LLM-powered content analysis",
    version=__version__,
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
cors_origins = [origin.strip() for origin in settings.CORS_ORIGINS.split(',')]
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(analyze.router, tags=["Analysis"])
app.include_router(embed.router, tags=["Embeddings"])
app.include_router(health.router, tags=["Health"])


@app.on_event("startup")
async def startup_event():
    """Run on application startup."""
    logger.info("=" * 60)
    logger.info(f"BEE ML Service v{__version__} starting...")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info(f"Provider priority: {settings.PROVIDER_PRIORITY}")
    logger.info(f"Ollama enabled: {settings.ENABLE_OLLAMA}")
    logger.info(f"Groq configured: {settings.GROQ_API_KEY is not None}")
    logger.info(f"Gemini configured: {settings.GEMINI_API_KEY is not None}")
    logger.info(f"Redis configured: {settings.REDIS_URL is not None}")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown."""
    logger.info("BEE ML Service shutting down...")


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint with service information."""
    return {
        "service": "BEE ML Service",
        "version": __version__,
        "description": "Blocnet Edge Engine Machine Learning Service",
        "docs": "/docs",
        "health": "/health"
    }


@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler for unhandled errors."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "error": str(exc) if settings.ENVIRONMENT == "development" else "An error occurred"
        }
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.ENVIRONMENT == "development",
        log_level=settings.LOG_LEVEL.lower()
    )
