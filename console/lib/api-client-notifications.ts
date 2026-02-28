import { apiFetch } from "./api-client-http";

export const notificationsApi = {
  broadcastNotification: (body: {
    title: string;
    body: string;
    target: "all" | "hunters" | "users" | "specific";
    userIds?: string[];
  }) =>
    apiFetch<{
      insertedCount: number;
      sentCount: number;
      failureCount: number;
      recipientCount: number;
      skipped: boolean;
      skipReason?: string | null;
    }>("/notifications/broadcast", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  getNotificationEmailStatus: () =>
    apiFetch<{
      configured: boolean;
      reason: string | null;
      defaultFromAddress: string;
      defaultFromName: string;
      adminFromAddress: string;
      adminFromName: string;
      allowedFromAddresses: string[];
      replyTo: string | null;
      broadcastRatePerMinute: number;
    }>("/notifications/email/status"),

  broadcastEmail: (body: {
    subject: string;
    message: string;
    target: "all" | "hunters" | "users" | "specific";
    userIds?: string[];
    previewText?: string;
    fromAddress?: string;
    fromName?: string;
    replyTo?: string;
    ctaLabel?: string;
    ctaUrl?: string;
  }) =>
    apiFetch<{
      recipientCount: number;
      delivered: number;
      failed: number;
      skipped: number;
      skippedReason: string | null;
      estimatedRatePerMinute: number;
    }>("/notifications/broadcast-email", {
      method: "POST",
      body: JSON.stringify(body),
    }),
};
