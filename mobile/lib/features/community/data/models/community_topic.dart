enum CommunityTopic {
  general,
  marketTalk,
  introductions;

  String get apiValue {
    switch (this) {
      case CommunityTopic.general:
        return 'general';
      case CommunityTopic.marketTalk:
        return 'market_talk';
      case CommunityTopic.introductions:
        return 'introductions';
    }
  }

  String get label {
    switch (this) {
      case CommunityTopic.general:
        return 'General';
      case CommunityTopic.marketTalk:
        return 'Market Talk';
      case CommunityTopic.introductions:
        return 'Introductions';
    }
  }

  static CommunityTopic fromApi(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'market_talk':
        return CommunityTopic.marketTalk;
      case 'introductions':
        return CommunityTopic.introductions;
      default:
        return CommunityTopic.general;
    }
  }
}
