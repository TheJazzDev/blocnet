"""
Ollama provider for local LLM inference.

This provider runs models locally using Ollama (https://ollama.ai).
Advantages: Free, private, unlimited usage, no API keys.
Requirements: Ollama installed locally with models pulled.
"""

import httpx
import json
from typing import Dict, Optional
from ..base import LLMProvider, AnalysisResult, EmbeddingResult


class OllamaProvider(LLMProvider):
    """Free local LLM provider using Ollama."""

    def __init__(self, config: Dict):
        super().__init__(config)
        self.base_url = config.get('ollama_url', 'http://localhost:11434')
        self.model = config.get('ollama_model', 'llama3.3:70b')
        self.embedding_model = config.get('ollama_embedding_model', 'nomic-embed-text')
        self.timeout = config.get('ollama_timeout', 120.0)

    async def analyze_content(
        self,
        content: str,
        context: Optional[Dict] = None
    ) -> AnalysisResult:
        """Analyze crypto update content using local Ollama model."""

        # Build prompt with context if provided
        user_prompt = self._build_analysis_prompt(content, context)

        system_prompt = """You are a crypto project update analyzer for Blocnet Edge Engine (BEE).
Analyze updates and return JSON with this exact structure:
{
  "quality": 0.0-1.0,
  "sentiment": "positive" or "neutral" or "negative",
  "topics": ["topic1", "topic2", ...],
  "urgency_justification": "explanation of why this is urgent or not",
  "actionability": 0.0-1.0,
  "key_insights": ["insight1", "insight2", ...]
}

Quality scoring:
- 0.9-1.0: Exceptional - detailed technical updates, major milestones
- 0.7-0.9: High quality - substantial progress, clear impact
- 0.5-0.7: Good - regular updates, meaningful content
- 0.3-0.5: Low quality - vague, minimal substance
- 0.0-0.3: Very low - spam, no real content

Actionability scoring:
- 0.9-1.0: Requires immediate action (breaking changes, critical updates)
- 0.7-0.9: Should act soon (new features, important changes)
- 0.5-0.7: Worth monitoring (iterative improvements)
- 0.3-0.5: Informational (minor updates, general announcements)
- 0.0-0.3: No action needed (routine updates)

Be strict but fair. Return only valid JSON."""

        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/chat",
                    json={
                        "model": self.model,
                        "messages": [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": user_prompt}
                        ],
                        "stream": False,
                        "format": "json",
                        "options": {
                            "temperature": 0.3,  # Lower temperature for more consistent output
                            "top_p": 0.9
                        }
                    }
                )

                if response.status_code != 200:
                    raise Exception(f"Ollama API error: {response.status_code} - {response.text}")

                result = response.json()
                message = result['message']['content']

                # Parse JSON response
                try:
                    data = json.loads(message)
                except json.JSONDecodeError:
                    # Sometimes LLM might wrap JSON in markdown
                    if "```json" in message:
                        json_str = message.split("```json")[1].split("```")[0].strip()
                        data = json.loads(json_str)
                    elif "```" in message:
                        json_str = message.split("```")[1].split("```")[0].strip()
                        data = json.loads(json_str)
                    else:
                        raise

                # Ensure sentiment is valid
                valid_sentiments = ['positive', 'neutral', 'negative']
                if data.get('sentiment') not in valid_sentiments:
                    data['sentiment'] = 'neutral'

                # Clamp scores to valid range
                data['quality'] = max(0.0, min(1.0, float(data.get('quality', 0.5))))
                data['actionability'] = max(0.0, min(1.0, float(data.get('actionability', 0.5))))

                return AnalysisResult(
                    quality=data['quality'],
                    sentiment=data['sentiment'],
                    topics=data.get('topics', []),
                    urgency_justification=data.get('urgency_justification', ''),
                    actionability=data['actionability'],
                    key_insights=data.get('key_insights', []),
                    web_context_used=context is not None and len(context) > 0
                )

        except httpx.TimeoutException:
            raise Exception(f"Ollama timeout after {self.timeout}s - model might be too large or busy")
        except httpx.ConnectError:
            raise Exception(f"Cannot connect to Ollama at {self.base_url} - is Ollama running?")
        except Exception as e:
            raise Exception(f"Ollama analysis failed: {str(e)}")

    async def generate_embedding(
        self,
        text: str
    ) -> EmbeddingResult:
        """Generate vector embedding using Ollama."""

        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{self.base_url}/api/embeddings",
                    json={
                        "model": self.embedding_model,
                        "prompt": text
                    }
                )

                if response.status_code != 200:
                    raise Exception(f"Ollama embedding error: {response.status_code}")

                result = response.json()
                embedding = result['embedding']

                return EmbeddingResult(
                    embedding=embedding,
                    model=self.embedding_model,
                    dimensions=len(embedding)
                )

        except httpx.ConnectError:
            raise Exception(f"Cannot connect to Ollama at {self.base_url}")
        except Exception as e:
            raise Exception(f"Ollama embedding failed: {str(e)}")

    async def is_available(self) -> bool:
        """Check if Ollama is running and accessible."""

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{self.base_url}/api/tags")
                if response.status_code != 200:
                    self.last_availability_error = (
                        f"Ollama health check failed with HTTP {response.status_code} "
                        f"at {self.base_url}/api/tags"
                    )
                    return False

                data = response.json()
                models = data.get('models', [])
                model_names = [m.get('name', '') for m in models if m.get('name')]
                if self.model not in model_names:
                    similar = [
                        name for name in model_names
                        if name.split(':')[0] == self.model.split(':')[0]
                    ]
                    if similar:
                        self.last_availability_error = (
                            f"Configured model '{self.model}' not installed. "
                            f"Closest installed models: {', '.join(similar[:3])}"
                        )
                    else:
                        self.last_availability_error = (
                            f"Configured model '{self.model}' not installed in Ollama"
                        )
                    return False

                self.last_availability_error = None
                return True
        except httpx.ConnectError:
            self.last_availability_error = (
                f"Cannot connect to Ollama at {self.base_url} (is Ollama running?)"
            )
            return False
        except httpx.TimeoutException:
            self.last_availability_error = (
                f"Ollama health check timed out at {self.base_url}/api/tags"
            )
            return False
        except Exception as e:
            self.last_availability_error = f"Ollama availability check failed: {str(e)}"
            return False

    @property
    def supports_web_search(self) -> bool:
        """Ollama does not support web search natively."""
        return False

    def _build_analysis_prompt(self, content: str, context: Optional[Dict]) -> str:
        """Build analysis prompt with optional web context."""

        prompt = f"Analyze this crypto project update:\n\n{content}"

        if context:
            prompt += "\n\n--- Additional Context ---\n"

            if 'token_data' in context:
                token_data = context['token_data']
                prompt += f"\nToken Data: {json.dumps(token_data, indent=2)}"

            if 'protocol_data' in context:
                protocol_data = context['protocol_data']
                prompt += f"\nProtocol Data: {json.dumps(protocol_data, indent=2)}"

            if 'github_data' in context:
                github_data = context['github_data']
                prompt += f"\nGitHub Activity: {json.dumps(github_data, indent=2)}"

            if 'news_context' in context:
                news = context['news_context']
                prompt += f"\nRecent News: {json.dumps(news, indent=2)}"

        return prompt
