"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

type EdgeMlProviderLimitsCardProps = {
  edgeConfig: any;
  setEdgeConfig: React.Dispatch<React.SetStateAction<any>>;
  canMutateConfig: boolean;
  configSaving: boolean;
};

export function EdgeMlProviderLimitsCard({
  edgeConfig,
  setEdgeConfig,
  canMutateConfig,
  configSaving,
}: EdgeMlProviderLimitsCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Provider Models and Limits</CardTitle>
        <CardDescription>
          Provider model identifiers and cache/content limits used by analysis jobs.
        </CardDescription>
      </CardHeader>
      <CardContent className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <div className="space-y-2">
          <label className="text-xs font-medium">Ollama Model</label>
          <input
            type="text"
            className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            value={edgeConfig?.mlOllamaModel ?? ""}
            onChange={(e) =>
              setEdgeConfig((prev: any) =>
                prev ? { ...prev, mlOllamaModel: e.target.value } : prev,
              )
            }
            disabled={!canMutateConfig || !edgeConfig || configSaving}
          />
        </div>

        <div className="space-y-2">
          <label className="text-xs font-medium">Ollama Embedding Model</label>
          <input
            type="text"
            className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            value={edgeConfig?.mlOllamaEmbeddingModel ?? ""}
            onChange={(e) =>
              setEdgeConfig((prev: any) =>
                prev ? { ...prev, mlOllamaEmbeddingModel: e.target.value } : prev,
              )
            }
            disabled={!canMutateConfig || !edgeConfig || configSaving}
          />
        </div>

        <div className="space-y-2">
          <label className="text-xs font-medium">Ollama Timeout (ms)</label>
          <input
            type="number"
            className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            value={edgeConfig?.mlOllamaTimeout ?? 120000}
            onChange={(e) =>
              setEdgeConfig((prev: any) =>
                prev
                  ? {
                      ...prev,
                      mlOllamaTimeout: parseInt(e.target.value, 10) || 120000,
                    }
                  : prev,
              )
            }
            disabled={!canMutateConfig || !edgeConfig || configSaving}
            min={1000}
            max={300000}
          />
        </div>

        <div className="space-y-2">
          <label className="text-xs font-medium">Groq Model</label>
          <input
            type="text"
            className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            value={edgeConfig?.mlGroqModel ?? ""}
            onChange={(e) =>
              setEdgeConfig((prev: any) =>
                prev ? { ...prev, mlGroqModel: e.target.value } : prev,
              )
            }
            disabled={!canMutateConfig || !edgeConfig || configSaving}
          />
        </div>

        <div className="space-y-2">
          <label className="text-xs font-medium">Gemini Model</label>
          <input
            type="text"
            className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            value={edgeConfig?.mlGeminiModel ?? ""}
            onChange={(e) =>
              setEdgeConfig((prev: any) =>
                prev ? { ...prev, mlGeminiModel: e.target.value } : prev,
              )
            }
            disabled={!canMutateConfig || !edgeConfig || configSaving}
          />
        </div>

        <div className="space-y-2">
          <label className="text-xs font-medium">Gemini Embedding Model</label>
          <input
            type="text"
            className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            value={edgeConfig?.mlGeminiEmbeddingModel ?? ""}
            onChange={(e) =>
              setEdgeConfig((prev: any) =>
                prev ? { ...prev, mlGeminiEmbeddingModel: e.target.value } : prev,
              )
            }
            disabled={!canMutateConfig || !edgeConfig || configSaving}
          />
        </div>

        <div className="space-y-2">
          <label className="text-xs font-medium">Cache TTL (seconds)</label>
          <input
            type="number"
            className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            value={edgeConfig?.mlCacheTtl ?? 86400}
            onChange={(e) =>
              setEdgeConfig((prev: any) =>
                prev
                  ? { ...prev, mlCacheTtl: parseInt(e.target.value, 10) || 86400 }
                  : prev,
              )
            }
            disabled={!canMutateConfig || !edgeConfig || configSaving}
            min={60}
          />
        </div>

        <div className="space-y-2">
          <label className="text-xs font-medium">Max Content Length</label>
          <input
            type="number"
            className="h-9 w-full rounded-md border bg-background px-3 text-sm"
            value={edgeConfig?.mlMaxContentLength ?? 10000}
            onChange={(e) =>
              setEdgeConfig((prev: any) =>
                prev
                  ? {
                      ...prev,
                      mlMaxContentLength: parseInt(e.target.value, 10) || 10000,
                    }
                  : prev,
              )
            }
            disabled={!canMutateConfig || !edgeConfig || configSaving}
            min={1000}
          />
        </div>
      </CardContent>
    </Card>
  );
}
