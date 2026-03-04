'use client';

type RecoveryClipboardParams = {
  generatedRecoveryCodes: string[];
  setCopyStatus: (value: string | null) => void;
  setLastCopiedCode: (value: string | null) => void;
  setError: (value: string | null) => void;
};

export function createRecoveryClipboardActions(params: RecoveryClipboardParams) {
  async function copyToClipboard(
    value: string,
    successMessage: string,
    code?: string,
  ) {
    try {
      if (!navigator.clipboard) {
        throw new Error('Clipboard API unavailable');
      }
      await navigator.clipboard.writeText(value);
      params.setCopyStatus(successMessage);
      params.setLastCopiedCode(code ?? null);
    } catch {
      params.setCopyStatus(null);
      params.setLastCopiedCode(null);
      params.setError('Could not copy. Please copy manually.');
    }
  }

  async function copyAllRecoveryCodes() {
    if (params.generatedRecoveryCodes.length === 0) {
      return;
    }

    await copyToClipboard(
      params.generatedRecoveryCodes.join('\n'),
      'All recovery codes copied.',
    );
  }

  async function copyRecoveryCode(code: string) {
    await copyToClipboard(code, `Copied ${code}.`, code);
  }

  return {
    copyAllRecoveryCodes,
    copyRecoveryCode,
  };
}
