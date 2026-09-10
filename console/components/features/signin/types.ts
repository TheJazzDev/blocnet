export type SignInStage =
  | 'credentials'
  | 'setup2fa'
  | 'twoFactor'
  | 'recoveryCodes';

export type TwoFactorPreflight = {
  eligible: boolean;
  totpEnabled: boolean;
  policyRequired: boolean;
  challengeRequired: boolean;
};

export type EnrollmentResponse = {
  secret: string;
  otpAuthUrl: string;
  issuer: string;
  accountName: string;
  expiresAt: string;
};
