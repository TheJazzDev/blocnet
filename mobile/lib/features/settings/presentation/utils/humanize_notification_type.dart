/// Turns a catalog event type such as `project_update_published` into
/// "Project Update Published" for display.
String humanizeNotificationType(String raw) {
  return raw
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
