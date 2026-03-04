export interface AdminTwoFactorPreflight {
  eligible: boolean;
  totpEnabled: boolean;
  recoveryCodesRemaining: number;
  policyRequired: boolean;
  challengeRequired: boolean;
}

export interface AdminTwoFactorPolicy {
  id: string;
  require2faForAdminPanel: boolean;
  updatedById: string | null;
  updatedAt: string;
  summary: {
    eligibleUsers: number;
    enabledUsers: number;
    missingUsers: number;
  };
}

export interface AdminTwoFactorEnrollmentStartResponse {
  secret: string;
  otpAuthUrl: string;
  issuer: string;
  accountName: string;
  expiresAt: string;
}

export interface AdminTwoFactorEnrollmentConfirmResponse {
  enabled: true;
  recoveryCodes: string[];
  sessionToken: string;
  sessionExpiresAt: string;
}

export interface AdminTwoFactorRecoveryCodesResponse {
  recoveryCodes: string[];
}

export interface AdminTwoFactorDisableResponse {
  disabled: true;
}

export interface AdminTwoFactorLoginVerifyResponse {
  sessionToken: string;
  expiresAt: string;
}

export interface AdminTwoFactorSessionValidationResponse {
  valid: boolean;
  required: boolean;
  expiresAt: string | null;
}

export interface AdminSocialCredential {
  id: string;
  provider: string;
  accountLabel: string | null;
  username: string | null;
  notes: string | null;
  passwordMasked: string;
  createdById: string;
  updatedById: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AdminSocialCredentialsResponse {
  data: AdminSocialCredential[];
}

export interface AdminSocialCredentialRevealResponse {
  id: string;
  password: string;
}

