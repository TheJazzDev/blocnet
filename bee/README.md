# BEE ML Service 🐝

**Blocnet Edge Engine Machine Learning Service**

AI-powered content analysis service for Blocnet using free, open-source LLM models with automatic fallback and web enrichment capabilities.

---

## 🎯 Features

- **Multi-Provider Support**: Ollama (local), Groq (cloud), Gemini (cloud with web search)
- **Automatic Fallback**: Seamlessly switches providers if one fails
- **Plugin Architecture**: Easy to add new LLM providers
- **Content Analysis**: Quality scoring, sentiment analysis, topic extraction, actionability
- **Vector Embeddings**: Semantic similarity search
- **Web Enrichment**: Context from CoinGecko, DeFiLlama, GitHub, RSS feeds (Phase 2)
- **ML Re-ranking**: XGBoost-based personalized ranking (Phase 3)
- **Caching**: Redis or in-memory caching to reduce API calls
- **100% Free Options**: Run completely free with Ollama + public APIs

---

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- (Optional) Ollama installed locally
- (Optional) API keys for Groq/Gemini

### Installation

```bash
# Clone the repo (if not already in blocnet monorepo)
cd blocnet/bee

# Fast setup (runtime-only deps by default)
./setup.sh

# Activate environment in your current shell
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

Optional setup modes:

```bash
# Include heavy local embeddings stack (sentence-transformers/torch)
./setup.sh --with-embeddings

# Include dev tooling
./setup.sh --with-dev

# Install everything
./setup.sh --full

# Reuse existing deps and skip pip entirely
./setup.sh --skip-install
```

Manual dependency files:

- `requirements-runtime.txt` (default)
- `requirements-embeddings.txt` (optional, heavy)
- `requirements-dev.txt` (optional)
- `requirements.txt` (full install meta-file)

### Setup Ollama (Recommended for Free Local LLM)

```bash
# Install Ollama
curl https://ollama.ai/install.sh | sh

# Pull models
ollama pull llama3.3:70b        # Main model (requires 40GB+ RAM)
# OR for lighter option:
ollama pull llama3.2:3b         # Lighter model (8GB RAM)

# Pull embedding model
ollama pull nomic-embed-text

# Verify installation
ollama run llama3.3:70b "Hello!"
```

### Get API Keys (Optional)

**Groq (Free Tier: 14,400 requests/day)**
1. Visit https://console.groq.com
2. Sign up and get API key
3. Add to `.env`: `GROQ_API_KEY=your_key_here`

**Gemini (Free Tier: 60 requests/minute)**
1. Visit https://ai.google.dev
2. Get API key
3. Add to `.env`: `GEMINI_API_KEY=your_key_here`

### Run the Service

```bash
# Development mode (with auto-reload)
python -m app.main

# Or using uvicorn directly
uvicorn app.main:app --reload --host 0.0.0.0 --port 8083
```

The service will be available at:
- **API**: http://localhost:8083
- **Docs**: http://localhost:8083/docs
- **Health**: http://localhost:8083/health

---

## 📖 API Endpoints

### Content Analysis

**POST /analyze**

Analyze crypto update content with LLM.

```bash
curl -X POST http://localhost:8083/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "content": "We just integrated with Uniswap V4 hooks!",
    "require_web_search": false
  }'
```

Response:
```json
{
  "analysis": {
    "quality": 0.85,
    "sentiment": "positive",
    "topics": ["integration", "DeFi", "Uniswap"],
    "urgency_justification": "Major integration with top DEX protocol",
    "actionability": 0.9,
    "key_insights": [
      "Integration with Uniswap V4 hooks enables advanced trading features",
      "Increases protocol credibility and potential user base"
    ],
    "web_context_used": false
  },
  "provider_used": "ollama",
  "cached": false
}
```

**POST /analyze/batch**

Analyze multiple updates in batch (max 50).

```bash
curl -X POST http://localhost:8083/analyze/batch \
  -H "Content-Type: application/json" \
  -d '[
    {"content": "Update 1..."},
    {"content": "Update 2..."}
  ]'
```

### Embeddings

**POST /embed**

Generate vector embedding for text.

```bash
curl -X POST http://localhost:8083/embed \
  -H "Content-Type: application/json" \
  -d '{
    "text": "DeFi protocol integration"
  }'
```

Response:
```json
{
  "embedding": {
    "embedding": [0.123, -0.456, 0.789, ...],
    "model": "nomic-embed-text",
    "dimensions": 768
  },
  "provider_used": "ollama",
  "cached": false
}
```

### Health & Status

**GET /health**

Check service health and provider status.

```bash
curl http://localhost:8083/health
```

Response:
```json
{
  "status": "healthy",
  "version": "0.1.0",
  "timestamp": "2026-02-28T12:00:00",
  "providers": [
    {
      "name": "ollama",
      "available": true,
      "supports_web_search": false,
      "priority": 0
    },
    {
      "name": "groq",
      "available": true,
      "supports_web_search": false,
      "priority": 1
    },
    {
      "name": "gemini",
      "available": true,
      "supports_web_search": true,
      "priority": 2
    }
  ]
}
```

**GET /providers**

List all configured providers.

**POST /providers/refresh**

Refresh provider availability cache.

---

## ⚙️ Configuration

### Environment Variables

See `.env.example` for all configuration options.

**Key Settings:**

```env
# Provider priority (tries in order)
PROVIDER_PRIORITY=ollama,groq,gemini

# Ollama (local - FREE)
ENABLE_OLLAMA=true
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.3:70b

# Groq (cloud - FREE tier)
GROQ_API_KEY=your_groq_key
GROQ_MODEL=llama-3.3-70b-versatile

# Gemini (cloud with search - FREE tier)
GEMINI_API_KEY=your_gemini_key
GEMINI_MODEL=gemini-2.0-flash-exp
```

### Provider Priority

The service tries providers in the order specified by `PROVIDER_PRIORITY`. If the first provider fails or is unavailable, it automatically falls back to the next one.

**Recommended configurations:**

**Free Local:**
```env
PROVIDER_PRIORITY=ollama
ENABLE_OLLAMA=true
```

**Free Cloud:**
```env
PROVIDER_PRIORITY=groq,gemini
GROQ_API_KEY=your_key
GEMINI_API_KEY=your_key
```

**Hybrid (Best):**
```env
PROVIDER_PRIORITY=ollama,groq,gemini
ENABLE_OLLAMA=true
GROQ_API_KEY=your_key
GEMINI_API_KEY=your_key
```

---

## 🐳 Docker Deployment

### Build Image

```bash
cd bee
docker build -t bee-ml-service .
```

### Run Container

```bash
docker run -d \
  --name bee \
  -p 8083:8083 \
  --env-file .env \
  bee-ml-service
```

### With Ollama

If using Ollama, you need to either:

1. **Run Ollama on host** and set `OLLAMA_URL=http://host.docker.internal:11434`
2. **Run Ollama in container** and link them

---

## 🚢 Deployment (Railway/Fly.io)

### Railway

1. Create new project
2. Connect to GitHub repo
3. Set root directory to `bee`
4. Add environment variables
5. Deploy

### Fly.io

```bash
cd bee

# Create fly.toml
fly launch --no-deploy

# Set secrets
fly secrets set GROQ_API_KEY=your_key
fly secrets set GEMINI_API_KEY=your_key

# Deploy
fly deploy
```

---

## 🧪 Testing

```bash
# Install dev dependencies
pip install pytest pytest-asyncio

# Run tests
pytest

# With coverage
pytest --cov=app tests/
```

---

## 📊 Integration with Backend

### NestJS Backend Integration

```typescript
// backend/src/edge-engine/ml-client.service.ts
import axios from 'axios';

@Injectable()
export class MLClientService {
  private readonly baseUrl = process.env.BEE_ML_URL || 'http://localhost:8083';

  async analyzeUpdate(content: string, context?: any) {
    const response = await axios.post(`${this.baseUrl}/analyze`, {
      content,
      context,
      require_web_search: false
    });

    return response.data.analysis;
  }

  async generateEmbedding(text: string) {
    const response = await axios.post(`${this.baseUrl}/embed`, {
      text
    });

    return response.data.embedding;
  }

  async checkHealth() {
    const response = await axios.get(`${this.baseUrl}/health`);
    return response.data;
  }
}
```

---

## 🗺️ Roadmap

### ✅ Phase 1: Foundation (Current)
- [x] Multi-provider architecture
- [x] Ollama, Groq, Gemini providers
- [x] Content analysis endpoint
- [x] Embedding generation
- [x] Automatic fallback
- [x] Health checks

### 🚧 Phase 2: Web Enrichment (Next)
- [ ] CoinGecko integration (token prices, market data)
- [ ] DeFiLlama integration (protocol metrics, TVL)
- [ ] GitHub integration (repo activity)
- [ ] RSS feed aggregation (crypto news)
- [ ] Entity extraction (tokens, protocols, chains)
- [ ] Context-enhanced analysis

### 📅 Phase 3: ML Re-ranking
- [ ] Engagement tracking (clicks, view duration)
- [ ] Feature engineering
- [ ] XGBoost training pipeline
- [ ] Personalized re-ranking
- [ ] A/B testing framework

### 🔮 Phase 4: Advanced Features
- [ ] User preference learning
- [ ] Topic modeling
- [ ] Anomaly detection
- [ ] Predictive scoring
- [ ] Multi-modal analysis (images, charts)

---

## 💰 Cost Breakdown

### Completely Free Setup
- **Ollama**: $0 (local)
- **Public APIs**: $0 (CoinGecko, DeFiLlama, GitHub)
- **Total**: $0/month

**Requires**: 8GB+ RAM for Ollama

### Free Cloud Setup
- **Groq**: $0 (14,400 req/day free)
- **Gemini**: $0 (60 req/min free)
- **Public APIs**: $0
- **Total**: $0/month

**Requires**: Internet connection, API keys

### Hybrid (Recommended)
- **Ollama + Groq + Gemini**: $0/month
- **Deployment**: $5-20/month (Railway/Fly.io)
- **Total**: $5-20/month

---

## 🐛 Troubleshooting

### Ollama Connection Error

```
Cannot connect to Ollama at http://localhost:11434
```

**Solution**:
```bash
# Check if Ollama is running
ollama list

# Start Ollama (usually auto-starts)
ollama serve

# Verify models are pulled
ollama pull llama3.3:70b
```

### Provider Not Available

Check provider configuration in `.env` and verify API keys are correct.

```bash
# Test health endpoint
curl http://localhost:8083/health

# Refresh providers
curl -X POST http://localhost:8083/providers/refresh
```

### Out of Memory (Ollama)

If using llama3.3:70b and getting OOM errors:

```bash
# Use lighter model
ollama pull llama3.2:3b

# Update .env
OLLAMA_MODEL=llama3.2:3b
```

---

## 📝 License

Part of the Blocnet project.

---

## 🤝 Contributing

1. Add new provider in `app/models/providers/`
2. Implement `LLMProvider` interface
3. Register in `app/models/registry.py`
4. Update documentation
5. Submit PR

---

## 📧 Support

For issues and questions:
- Open issue in GitHub repo
- Check existing issues first
- Provide logs and environment details

---

**Built with ❤️ for the Blocnet community**
