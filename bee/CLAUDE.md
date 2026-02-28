# CLAUDE.md - BEE ML Service

## Project Overview

**BEE (Blocnet Edge Engine)** is a Python FastAPI service that provides AI-powered content analysis and embeddings for Blocnet. It uses a plugin-based architecture to support multiple LLM providers with automatic fallback.

---

## Architecture

### Core Components

1. **LLM Providers** (`app/models/providers/`)
   - Abstract base class: `LLMProvider`
   - Implementations: `OllamaProvider`, `GroqProvider`, `GeminiProvider`
   - Each provider must implement: `analyze_content()`, `generate_embedding()`, `is_available()`, `supports_web_search`

2. **Provider Registry** (`app/models/registry.py`)
   - Manages multiple providers
   - Automatic fallback on failure
   - Priority-based selection
   - Availability caching

3. **API Endpoints** (`app/api/`)
   - `/analyze` - Content analysis
   - `/embed` - Vector embeddings
   - `/health` - Service health
   - `/providers` - List providers

4. **Configuration** (`app/config.py`)
   - Environment-based settings
   - Provider priority configuration
   - API keys and URLs

5. **Utilities** (`app/utils/`)
   - `cache.py` - Redis/in-memory caching
   - `logger.py` - Logging setup

---

## Development Guidelines

### Adding a New Provider

1. Create provider file in `app/models/providers/new_provider.py`
2. Inherit from `LLMProvider` base class
3. Implement all abstract methods
4. Register in `app/models/registry.py`
5. Add configuration to `app/config.py`
6. Update `.env.example`

Example:
```python
from ..base import LLMProvider, AnalysisResult, EmbeddingResult

class NewProvider(LLMProvider):
    def __init__(self, config: Dict):
        super().__init__(config)
        self.api_key = config.get('new_provider_api_key')

    async def analyze_content(self, content, context=None):
        # Implementation
        pass

    async def generate_embedding(self, text):
        # Implementation
        pass

    async def is_available(self):
        return self.api_key is not None

    @property
    def supports_web_search(self):
        return False
```

### Adding a New Endpoint

1. Create router file in `app/api/new_endpoint.py`
2. Import router in `app/main.py`
3. Add Pydantic models for request/response
4. Use dependency injection for registry
5. Add proper error handling

---

## Testing

```bash
# Run tests
pytest

# With coverage
pytest --cov=app tests/

# Specific test
pytest tests/test_providers.py
```

---

## Common Tasks

### Update Dependencies

```bash
# Update specific package
pip install --upgrade groq

# Update requirements.txt
pip freeze > requirements.txt
```

### Add Web Enrichment Client

1. Create client in `app/clients/new_client.py`
2. Implement data fetching methods
3. Add error handling and retries
4. Cache results
5. Use in `context` parameter for analysis

### Train ML Model

1. Collect engagement data from backend
2. Create training script in `scripts/train_reranker.py`
3. Extract features from BEE scores + web data
4. Train XGBoost model
5. Save model artifact
6. Create `/rerank` endpoint
7. Load model in service startup

---

## Environment Variables

See `.env.example` for all options. Key variables:

- `PROVIDER_PRIORITY` - Order to try providers (comma-separated)
- `OLLAMA_URL` - Ollama server URL
- `GROQ_API_KEY` - Groq API key
- `GEMINI_API_KEY` - Gemini API key
- `REDIS_URL` - Redis URL for caching (optional)

---

## Deployment

### Local Development

```bash
python -m app.main
```

### Docker

```bash
docker build -t bee .
docker run -p 8000:8000 --env-file .env bee
```

### Railway/Fly.io

See README.md for deployment instructions.

---

## Integration with Backend

The NestJS backend should call BEE endpoints:

```typescript
// backend/src/edge-engine/edge-engine.service.ts

async buildFeed(userId: string) {
  const candidates = await this.generateCandidates(userId);

  // Call BEE for ML analysis
  const enriched = await axios.post(
    `${process.env.BEE_ML_URL}/analyze/batch`,
    candidates.map(c => ({
      content: c.update.content,
      context: { /* web data */ }
    }))
  );

  // Use ML scores to enhance ranking
  return this.rankWithMLScores(candidates, enriched.data);
}
```

---

## Roadmap

### Phase 2: Web Enrichment
- [ ] CoinGecko client
- [ ] DeFiLlama client
- [ ] GitHub client
- [ ] RSS aggregator
- [ ] Entity extraction
- [ ] `/enrich` endpoint

### Phase 3: ML Re-ranking
- [ ] Engagement data model
- [ ] Feature engineering
- [ ] Training pipeline
- [ ] Model serving
- [ ] `/rerank` endpoint

---

## Troubleshooting

### Provider Not Available

Check:
1. API keys in `.env`
2. Ollama is running (if using)
3. Network connectivity
4. Provider rate limits

Refresh providers: `POST /providers/refresh`

### High Latency

Solutions:
1. Enable caching (Redis)
2. Use faster provider (Groq)
3. Use lighter models
4. Batch requests

### Memory Issues (Ollama)

Use lighter model:
```bash
ollama pull llama3.2:3b
```

Update `.env`:
```
OLLAMA_MODEL=llama3.2:3b
```

---

## Code Standards

- Use async/await for all I/O operations
- Add type hints to all functions
- Use Pydantic models for validation
- Log at appropriate levels
- Handle errors gracefully with fallback
- Cache expensive operations
- Write docstrings for public methods

---

## Performance Tips

1. **Batch requests** when possible
2. **Cache LLM responses** (24h TTL recommended)
3. **Use Groq** for speed (500+ tokens/sec)
4. **Use Ollama** for unlimited free usage
5. **Enable Redis** for distributed caching
6. **Monitor provider availability** to avoid failed requests

---

## Security

- Never log API keys
- Validate all inputs (Pydantic)
- Rate limit endpoints (TODO)
- Use HTTPS in production
- Sanitize user content before LLM
- Implement authentication (TODO - integrate with backend auth)

---

This is a living document. Update as the project evolves.
