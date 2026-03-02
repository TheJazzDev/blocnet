const MESSAGE_KEYS = [
  "message",
  "detail",
  "error_description",
  "error",
  "reason",
  "title",
] as const;

function maybeParseJson(input: string): unknown {
  const trimmed = input.trim();
  if (!trimmed) {
    return null;
  }

  const startsLikeJson =
    trimmed.startsWith("{") ||
    trimmed.startsWith("[") ||
    trimmed.startsWith('"');
  if (!startsLikeJson) {
    return trimmed;
  }

  try {
    return JSON.parse(trimmed);
  } catch {
    return trimmed;
  }
}

function firstNonEmpty(messages: string[]): string | null {
  for (const message of messages) {
    if (message.trim().length > 0) {
      return message;
    }
  }
  return null;
}

export function extractApiErrorMessage(
  input: unknown,
  fallback = "Request failed",
): string {
  if (input == null) {
    return fallback;
  }

  if (typeof input === "string") {
    const parsed = maybeParseJson(input);
    if (typeof parsed === "string") {
      return parsed.trim() || fallback;
    }
    return extractApiErrorMessage(parsed, fallback);
  }

  if (Array.isArray(input)) {
    const messages = input
      .map((item) => extractApiErrorMessage(item, ""))
      .map((item) => item.trim())
      .filter(Boolean);
    return firstNonEmpty(messages) ?? fallback;
  }

  if (typeof input === "object") {
    const record = input as Record<string, unknown>;

    for (const key of MESSAGE_KEYS) {
      const value = record[key];
      if (value === undefined) {
        continue;
      }
      const message = extractApiErrorMessage(value, "").trim();
      if (message) {
        return message;
      }
    }

    return fallback;
  }

  if (typeof input === "number" || typeof input === "boolean") {
    return String(input);
  }

  return fallback;
}
