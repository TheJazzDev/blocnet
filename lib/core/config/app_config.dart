class AppConfig {
  static const String appName = 'BlocNet';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Community driven blockchain networking app';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String notificationsCollection = 'notifications';
  static const String activitiesCollection = 'activities';

  // Pagination
  static const int postsPerPage = 20;
  static const int projectsPerPage = 20;
  static const int commentsPerPage = 50;
  static const int notificationsPerPage = 30;

  // Cache durations
  static const Duration cacheDuration = Duration(minutes: 5);

  // Image upload limits
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif'
  ];

  // URLs
  static const String supportEmail = 'support@blocnet.com';
  static const String websiteUrl = 'https://blocnet.com';
  static const String privacyPolicyUrl = 'https://blocnet.com/privacy';
  static const String termsOfServiceUrl = 'https://blocnet.com/terms';
}
