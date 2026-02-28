import { apiFetch } from "./api-client-http";
import type {
  AdminTwoFactorDisableResponse,
  AdminTwoFactorEnrollmentConfirmResponse,
  AdminTwoFactorEnrollmentStartResponse,
  AdminTwoFactorPolicy,
  AdminTwoFactorPreflight,
  AdminTwoFactorRecoveryCodesResponse,
  AdminTwoFactorSessionValidationResponse,
} from "./api";

export const securityApi = {
  getAdminTwoFactorPreflight: () =>
    apiFetch<AdminTwoFactorPreflight>("/admin/security/2fa/preflight"),

  getAdminTwoFactorPolicy: () =>
    apiFetch<AdminTwoFactorPolicy>("/admin/security/2fa/policy"),

  updateAdminTwoFactorPolicy: (body: { require2faForAdminPanel: boolean }) =>
    apiFetch<AdminTwoFactorPolicy>("/admin/security/2fa/policy", {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  startAdminTwoFactorEnrollment: () =>
    apiFetch<AdminTwoFactorEnrollmentStartResponse>(
      "/admin/security/2fa/enrollment/start",
      {
        method: "POST",
      },
    ),

  confirmAdminTwoFactorEnrollment: (body: { code: string }) =>
    apiFetch<AdminTwoFactorEnrollmentConfirmResponse>(
      "/admin/security/2fa/enrollment/confirm",
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  regenerateAdminTwoFactorRecoveryCodes: (body: {
    code?: string;
    recoveryCode?: string;
  }) =>
    apiFetch<AdminTwoFactorRecoveryCodesResponse>(
      "/admin/security/2fa/recovery/regenerate",
      {
        method: "POST",
        body: JSON.stringify(body),
      },
    ),

  disableAdminTwoFactor: (body: { code?: string; recoveryCode?: string }) =>
    apiFetch<AdminTwoFactorDisableResponse>("/admin/security/2fa/disable", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  validateAdminTwoFactorSession: (sessionToken?: string) =>
    apiFetch<AdminTwoFactorSessionValidationResponse>(
      "/admin/security/2fa/session/validate",
      {
        method: "POST",
        body: JSON.stringify({ sessionToken }),
      },
    ),
};
