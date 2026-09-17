/// Form validators shared by the auth screens.
library;

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email is required';
  if (!email.contains('@')) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? value) {
  if ((value ?? '').length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

/// Builds a validator that checks a confirmation field against [original].
String? Function(String?) confirmPasswordValidator(String Function() original) {
  return (value) => value != original() ? 'Passwords do not match' : null;
}
