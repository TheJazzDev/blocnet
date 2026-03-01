"""
Gemini provider with web grounding capabilities.

This provider uses Google's Gemini API with free tier (60 requests/min).
Advantages: Built-in web search (Google Search grounding), multimodal, free tier.
Requirements: Gemini API key from https://ai.google.dev
"""

import json
from typing import Dict, Optional
import google.generativeai as genai
from ..base import LLMProvider, AnalysisResult, EmbeddingResult


class GeminiProvider(LLMProvider):
    """Google Gemini with web grounding (search capability)."""

    def __init__(self, config: Dict):
        super().__init__(config)
        self.api_key = config.get('gemini_api_key')
        if self.api_key:
            genai.configure(api_key=self.api_key)
        self.model_name = config.get('gemini_model', 'gemini-2.0-flash-exp')
        self.embedding_model_name = config.get('gemini_embedding_model', 'models/text-embedding-004')

    async def analyze_content(
        self,
        content: str,
        context: Optional[Dict] = None
    ) -> AnalysisResult:
        """Analyze crypto update content using Gemini with optional web search."""

        if not self.api_key:
            raise ValueError("Gemini API key not configured")

        # Enable web search if context requests it or if no other context provided
        enable_search = False
        if context and context.get('enable_web_search', False):
            enable_search = True

        # Build model with optional web search
        tools = ['google_search_retrieval'] if enable_search else None

        model = genai.GenerativeModel(
            model_name=self.model_name,
            tools=tools
        )

        # Build prompt
        user_prompt = self._build_analysis_prompt(content, context, enable_search)

        prompt = f"""Analyze this crypto project update and return JSON with this exact structure:
{{
  "quality": 0.0-1.0,
  "sentiment": "positive" or "neutral" or "negative",
  "topics": ["topic1", "topic2", ...],
  "urgency_justification": "explanation of why this is urgent or not",
  "actionability": 0.0-1.0,
  "key_insights": ["insight1", "insight2", ...]
}}

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

Be strict but fair.

{user_prompt}"""

        try:
            response = await model.generate_content_async(
                prompt,
                generation_config=genai.GenerationConfig(
                    response_mime_type="application/json",
                    temperature=0.3
                )
            )

            # Parse JSON response
            data = json.loads(response.text)

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
                web_context_used=enable_search or (context is not None and len(context) > 0)
            )

        except Exception as e:
            raise Exception(f"Gemini analysis failed: {str(e)}")

    async def generate_embedding(
        self,
        text: str
    ) -> EmbeddingResult:
        """Generate vector embedding using Gemini."""

        if not self.api_key:
            raise ValueError("Gemini API key not configured")

        try:
            result = genai.embed_content(
                model=self.embedding_model_name,
                content=text,
                task_type='retrieval_document'
            )

            embedding = result['embedding']

            return EmbeddingResult(
                embedding=embedding,
                model=self.embedding_model_name,
                dimensions=len(embedding)
            )

        except Exception as e:
            raise Exception(f"Gemini embedding failed: {str(e)}")

    async def is_available(self) -> bool:
        """Check if Gemini API key is configured."""
        available = self.api_key is not None and len(self.api_key) > 0
        self.last_availability_error = None if available else "Gemini API key not configured"
        return available

    @property
    def supports_web_search(self) -> bool:
        """Gemini supports Google Search grounding."""
        return True

    def _build_analysis_prompt(
        self,
        content: str,
        context: Optional[Dict],
        enable_search: bool
    ) -> str:
        """Build analysis prompt with optional web context."""

        prompt = f"Update content:\n{content}"

        if enable_search:
            prompt += "\n\nSearch the web for additional context about mentioned projects, tokens, protocols, or events to enhance your analysis."

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
