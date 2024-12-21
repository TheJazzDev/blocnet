import 'package:blocknet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocknet/features/projects/data/models/project_model.dart';

List<Project> dummyProjects = [
  Project(
    id: 'project1',
    name: 'Alpha Blockchain',
    logo:
        'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
    description:
        'Alpha Blockchain is a leading platform in decentralized finance and NFTs.',
    primaryTag: PrimaryTag.solana,
    followerCount: 12000,
    adminId: 'admin1',
    website: 'https://alphablockchain.com',
    socials: {
      'twitter': 'https://twitter.com/alphablockchain',
      'discord': 'https://discord.gg/alphablockchain',
      'telegram': null,
      'github': 'https://github.com/alphablockchain',
    },
    apps: {
      'android':
          'https://play.google.com/store/apps/details?id=alphablockchain',
      'ios': 'https://apps.apple.com/app/alphablockchain',
    },
    postIds: {'post1', 'post2', 'post3'},
  ),
  Project(
    id: 'project2',
    name: 'Beta Network',
    logo:
        'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
    description:
        'Beta Network powers decentralized applications for the metaverse.',
    primaryTag: PrimaryTag.ethereum,
    followerCount: 8000,
    adminId: 'admin2',
    website: 'https://betanetwork.com',
    socials: {
      'twitter': 'https://twitter.com/betanetwork',
      'discord': 'https://discord.gg/betanetwork',
      'telegram': 'https://t.me/betanetwork',
      'github': null,
    },
    apps: {
      'android': null,
      'ios': 'https://apps.apple.com/app/betanetwork',
    },
    postIds: {'post4', 'post5', 'post6'},
  ),
  Project(
    id: 'project3',
    name: 'BlocNet',
    logo:
        'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
    description: 'Top community update/networking mobile application.',
    primaryTag: PrimaryTag.ethereum,
    followerCount: 8000,
    adminId: 'admin3',
    website: 'https://blocnet.com',
    socials: {
      'twitter': 'https://twitter.com/blocnet',
      'discord': 'https://discord.gg/blocnet',
      'telegram': 'https://t.me/blocnet',
      'github': null,
    },
    apps: {
      'android': null,
      'ios': 'https://apps.apple.com/app/blocnet',
    },
    postIds: {'post7', 'post8'},
  ),
];
