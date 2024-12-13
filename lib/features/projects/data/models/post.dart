import 'package:blocknet/features/projects/data/models/primary_tag.dart';
import 'package:blocknet/features/projects/data/models/priority.dart';
import 'package:blocknet/features/projects/data/models/secondary_tag.dart';

class Post {
  final String id;
  final String projectTitle;
  final PrimaryTag primaryTag;
  final List<SecondaryTag> secondaryTags;
  final String logoUrl;
  final String title;
  final String description;
  final DateTime createdAt;
  final Priority priority;

  Post({
    required this.id,
    required this.projectTitle,
    required this.primaryTag,
    required List<SecondaryTag> secondaryTags,
    required this.logoUrl,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.priority,
  }) : secondaryTags = secondaryTags.toSet().toList();

  // Factory method to create a Post from JSON data
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      projectTitle: json['projectTitle'],
      primaryTag: json['primaryTag'],
      secondaryTags: List<SecondaryTag>.from(json['secondaryTags'] ?? []),
      logoUrl: json['logoUrl'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      priority: json['priority'],
    );
  }

  // Method to convert a Post to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectTitle': projectTitle,
      'primaryTag': primaryTag,
      'secondaryTags': secondaryTags,
      'logoUrl': logoUrl,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
    };
  }

  // Static list of dummy posts
  static List<Post> dummyPosts = [
    Post(
      id: '1',
      projectTitle: 'Over protocol',
      primaryTag: PrimaryTag.solana,
      secondaryTags: [
        SecondaryTag.airdrops,
        SecondaryTag.mining,
        SecondaryTag.nft,
        SecondaryTag.launching
      ],
      logoUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      title:
          'Critical exploit found in Bitcoin wallet. Move your funds immediately!',
      description:
          'Due to unforeseen technical issues, Bitcoin has extended the vesting period for its tokens. The unlock date is now scheduled for December 15. Be sure to adjust your trading strategies in light of this delay.',
      createdAt: DateTime.now(),
      priority: Priority.medium,
    ),
    Post(
      id: '2',
      projectTitle: 'Alpha blockchain',
      primaryTag: PrimaryTag.ethereum,
      secondaryTags: [
        SecondaryTag.partnership,
        SecondaryTag.staking,
        SecondaryTag.mining,
        SecondaryTag.airdrops,
        SecondaryTag.governance,
      ],
      logoUrl:
          'https://pbs.twimg.com/profile_images/1866175744402948096/KtXzmRGA_400x400.jpg',
      title: 'New Ethereum update rolling out next week!',
      description:
          'Ethereum developers will be launching a new update next week to enhance scalability.',
      createdAt: DateTime.now(),
      priority: Priority.high,
    ),
    Post(
      id: '3',
      projectTitle: 'SpaceX Ventures',
      primaryTag: PrimaryTag.solana,
      secondaryTags: [
        SecondaryTag.governance,
        SecondaryTag.nft,
        SecondaryTag.partnership,
        SecondaryTag.security,
        SecondaryTag.icoIdo,
        SecondaryTag.governance
      ],
      logoUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      title: 'SpaceX mission to Mars launches next year!',
      description:
          'SpaceX announces plans for the first manned mission to Mars. Exciting times ahead!',
      createdAt: DateTime.now(),
      priority: Priority.high,
    ),
    Post(
      id: '4',
      projectTitle: 'MetaVision',
      primaryTag: PrimaryTag.ethereum,
      secondaryTags: [
        SecondaryTag.nft,
        SecondaryTag.metaverse,
        SecondaryTag.gaming,
      ],
      logoUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      title: 'Meta introduces new AR glasses!',
      description:
          'Meta’s new AR glasses revolutionize user interaction with the digital world.',
      createdAt: DateTime.now(),
      priority: Priority.medium,
    ),
    Post(
      id: '5',
      projectTitle: 'CryptoX',
      primaryTag: PrimaryTag.telegramNetwork,
      secondaryTags: [SecondaryTag.wallet, SecondaryTag.security],
      logoUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      title: 'Bitcoin wallet breach alert!',
      description:
          'A critical security flaw in Bitcoin wallets has been discovered. Immediate update required.',
      createdAt: DateTime.now(),
      priority: Priority.medium,
    ),
    Post(
      id: '6',
      projectTitle: 'AI Trends',
      primaryTag: PrimaryTag.solana,
      secondaryTags: [SecondaryTag.staking, SecondaryTag.mining],
      logoUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      title: 'AI revolution in blockchain technology.',
      description:
          'AI is rapidly being integrated into blockchain for better scalability and automation.',
      createdAt: DateTime.now(),
      priority: Priority.low,
    ),
    Post(
      id: '7',
      projectTitle: 'Breakthrough',
      primaryTag: PrimaryTag.iceOpenNetwork,
      secondaryTags: [SecondaryTag.governance, SecondaryTag.nft],
      logoUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      title: 'Ethereum 2.0 updates rolling out!',
      description:
          'Ethereum 2.0 upgrades are live, focusing on faster transactions and reduced gas fees.',
      createdAt: DateTime.now(),
      priority: Priority.high,
    ),
    Post(
      id: '8',
      projectTitle: 'Solana Innovations',
      primaryTag: PrimaryTag.solana,
      secondaryTags: [SecondaryTag.tokenBurn, SecondaryTag.ido],
      logoUrl:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      title: 'Solana hits new milestone in transaction speeds.',
      description:
          'Solana is now processing over 65,000 transactions per second, making it a leader in blockchain scalability.',
      createdAt: DateTime.now(),
      priority: Priority.low,
    ),
  ];
}
