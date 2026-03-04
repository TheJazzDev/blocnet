"use client";

import { AlertCircle, CheckCircle2, Loader2, RefreshCw, Save, Settings2 } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";
import { Button } from "@/components/ui/button";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { formatDateTime } from "../../_lib/edge-admin";
import { useEdgeAdminData } from "../../_hooks/use-edge-admin-data";
import { EdgeMlProviderLimitsCard } from "./EdgeMlProviderLimitsCard";

export default function EdgeEngineSettingsPage() {
  const session = useAdminSession();
  const canMutateConfig = canMutateWallet(session.effectiveRoles);

  const {
    edgeConfig,
    setEdgeConfig,
    loading,
    refreshing,
    error,
    configSaving,
    recomputeRunning,
    configStatus,
    refresh,
    saveEdgeConfig,
    recomputeEdgeDecisions,
  } = useEdgeAdminData(7);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Edge Engine · Settings"
        description="Runtime toggles and ML configuration for rollout and model behavior."
      >
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={() => void refresh()} disabled={loading || refreshing}>
            {refreshing ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
            Refresh
          </Button>
        </div>
      </PageHeader>

      {error && (
        <Card className="border-destructive/30">
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      {loading ? (
        <Card>
          <CardContent className="pt-6">
            <LoadingSpinner className="py-10" />
          </CardContent>
        </Card>
      ) : (
        <>
          {!canMutateConfig && (
            <Card className="border-amber-500/30 bg-amber-500/5">
              <CardContent className="pt-6 text-sm text-amber-200">
                Read-only mode. Owner/Admin roles are required to save Edge Engine settings.
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <Settings2 className="h-4 w-4" />
                Runtime Toggles
              </CardTitle>
              <CardDescription>Primary switch for BEE and ML analysis availability.</CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-3">
              <div className="space-y-2">
                <label htmlFor="beeEnabled" className="text-sm font-medium">
                  Edge Engine Runtime
                </label>
                <select
                  id="beeEnabled"
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                  value={edgeConfig?.enabled ? "true" : "false"}
                  onChange={(event) =>
                    setEdgeConfig((prev) =>
                      prev ? { ...prev, enabled: event.target.value === "true" } : prev,
                    )
                  }
                  disabled={!canMutateConfig || !edgeConfig || configSaving}
                >
                  <option value="true">Enabled</option>
                  <option value="false">Disabled</option>
                </select>
              </div>

              <div className="space-y-2">
                <label htmlFor="mlEnabled" className="text-sm font-medium">
                  ML Runtime
                </label>
                <select
                  id="mlEnabled"
                  className="h-10 w-full rounded-md border bg-background px-3 text-sm"
                  value={edgeConfig?.mlEnabled ? "true" : "false"}
                  onChange={(event) =>
                    setEdgeConfig((prev) =>
                      prev ? { ...prev, mlEnabled: event.target.value === "true" } : prev,
                    )
                  }
                  disabled={!canMutateConfig || !edgeConfig || configSaving}
                >
                  <option value="true">Enabled</option>
                  <option value="false">Disabled</option>
                </select>
              </div>

              <div className="space-y-2">
                <p className="text-sm font-medium">Last Updated</p>
                <p className="rounded-md border px-3 py-2 text-sm text-muted-foreground">
                  {formatDateTime(edgeConfig?.updatedAt ?? null)}
                </p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">ML Service Runtime</CardTitle>
              <CardDescription>
                Network and provider-level controls used by machine-powered analysis.
              </CardDescription>
            </CardHeader>
            <CardContent className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <label className="text-xs font-medium">Service URL</label>
                <input
                  type="url"
                  className="h-9 w-full rounded-md border bg-background px-3 text-sm"
                  value={edgeConfig?.mlUrl ?? ""}
                  onChange={(e) =>
                    setEdgeConfig((prev) =>
                      prev ? { ...prev, mlUrl: e.target.value } : prev,
                    )
                  }
                  disabled={!canMutateConfig || !edgeConfig || configSaving}
                  placeholder="http://localhost:8083"
                />
                <p className="text-[11px] text-muted-foreground">
                  Use a full URL including protocol, for example <code>http://localhost:8083</code>.
                </p>
              </div>

              <div className="space-y-2">
                <label className="text-xs font-medium">Provider</label>
                <select
                  className="h-9 w-full rounded-md border bg-background px-3 text-sm"
                  value={edgeConfig?.mlProvider ?? "auto"}
                  onChange={(e) =>
                    setEdgeConfig((prev) =>
                      prev ? { ...prev, mlProvider: e.target.value } : prev,
                    )
                  }
                  disabled={!canMutateConfig || !edgeConfig || configSaving}
                >
                  <option value="auto">Auto (Fallback)</option>
                  <option value="ollama">Ollama (Local)</option>
                  <option value="groq">Groq (Cloud)</option>
                  <option value="gemini">Gemini (Web Search)</option>
                </select>
              </div>

              <div className="space-y-2">
                <label className="text-xs font-medium">Request Timeout (ms)</label>
                <input
                  type="number"
                  className="h-9 w-full rounded-md border bg-background px-3 text-sm"
                  value={edgeConfig?.mlTimeout ?? 10000}
                  onChange={(e) =>
                    setEdgeConfig((prev) =>
                      prev ? { ...prev, mlTimeout: parseInt(e.target.value, 10) || 10000 } : prev,
                    )
                  }
                  disabled={!canMutateConfig || !edgeConfig || configSaving}
                  min={1000}
                  max={300000}
                />
              </div>

              <label className="flex items-center space-x-2 pt-6">
                <input
                  type="checkbox"
                  className="h-4 w-4"
                  checked={edgeConfig?.mlWebSearch ?? false}
                  onChange={(e) =>
                    setEdgeConfig((prev) =>
                      prev ? { ...prev, mlWebSearch: e.target.checked } : prev,
                    )
                  }
                  disabled={!canMutateConfig || !edgeConfig || configSaving}
                />
                <span className="text-xs font-medium">Enable web-search grounding</span>
              </label>
            </CardContent>
          </Card>

          <EdgeMlProviderLimitsCard
            edgeConfig={edgeConfig}
            setEdgeConfig={setEdgeConfig}
            canMutateConfig={canMutateConfig}
            configSaving={configSaving}
          />

          <Card>
            <CardContent className="flex flex-wrap items-center justify-between gap-3 pt-6">
              <p className="text-xs text-muted-foreground">
                Settings apply immediately to new decision generation jobs.
              </p>
              <div className="flex flex-wrap items-center gap-2">
                <Button
                  variant="outline"
                  onClick={() => void recomputeEdgeDecisions()}
                  disabled={!canMutateConfig || recomputeRunning || configSaving}
                >
                  {recomputeRunning ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                  Recompute Now
                </Button>
                <Button
                  onClick={() => void saveEdgeConfig()}
                  disabled={!canMutateConfig || !edgeConfig || configSaving || recomputeRunning}
                >
                  {configSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                  Save Configuration
                </Button>
              </div>
            </CardContent>
          </Card>

          {configStatus ? (
            <Alert variant={configStatus.type === "error" ? "destructive" : "default"}>
              {configStatus.type === "error" ? (
                <AlertCircle className="h-4 w-4" />
              ) : (
                <CheckCircle2 className="h-4 w-4" />
              )}
              <AlertTitle>
                {configStatus.type === "error" ? "Unable to Save Settings" : "Settings Saved"}
              </AlertTitle>
              <AlertDescription>{configStatus.message}</AlertDescription>
            </Alert>
          ) : null}
        </>
      )}
    </div>
  );
}
