import type { AdminSocialCredential } from "@/lib/api-client";

export type CredentialFormState = {
  provider: string;
  accountLabel: string;
  username: string;
  password: string;
  notes: string;
};

export const EMPTY_FORM: CredentialFormState = {
  provider: "",
  accountLabel: "",
  username: "",
  password: "",
  notes: "",
};

export function normalizeOptional(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export function prettyProvider(provider: string): string {
  return provider
    .split(/[_\-\s]+/)
    .filter(Boolean)
    .map((entry) => entry[0].toUpperCase() + entry.slice(1))
    .join(" ");
}

export function toEditForm(row: AdminSocialCredential): CredentialFormState {
  return {
    provider: row.provider,
    accountLabel: row.accountLabel ?? "",
    username: row.username ?? "",
    password: "",
    notes: row.notes ?? "",
  };
}
