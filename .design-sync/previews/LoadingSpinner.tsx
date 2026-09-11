import * as React from "react";
import { LoadingSpinner } from "blocnet-admin";

export const Default = () => <LoadingSpinner />;

export const CustomLabel = () => <LoadingSpinner label="Fetching leaderboard…" />;

export const InPanel = () => (
  <div className="w-96 rounded-lg border border-border bg-card">
    <LoadingSpinner className="min-h-40" label="Loading projects" />
  </div>
);
