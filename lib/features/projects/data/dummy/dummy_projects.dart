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
      followersCount: 12000,
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
      createdAt: DateTime.parse('2021-01-03'),
      postIds: {'post1', 'post2', 'post3'},
      details: '''
# Alpha Blockchain

- **Description**: Alpha Blockchain is a leading platform in decentralized finance and NFTs.
- **Primary Tag**: Solana
- **Followers**: 12,000
- **Website**: [alphablockchain.com](https://alphablockchain.com)
- **Socials**:
  - [Twitter](https://twitter.com/alphablockchain)
  - [Discord](https://discord.gg/alphablockchain)
  - GitHub: [alphablockchain](https://github.com/alphablockchain)
- **Apps**:
  - [Android](https://play.google.com/store/apps/details?id=alphablockchain)
  - [iOS](https://apps.apple.com/app/alphablockchain)
- **Created At**: January 3, 2021
- **Posts**: Post1, Post2, Post3

![Alpha Blockchain Logo](https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg)
    '''),
  Project(
      id: 'project2',
      name: 'Beta Network',
      logo:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      description:
          'Beta Network powers decentralized applications for the metaverse.',
      primaryTag: PrimaryTag.ethereum,
      followersCount: 8000,
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
      createdAt: DateTime.parse('2024-11-09'),
      postIds: {'post4', 'post5', 'post6'},
      details: '''
# Beta Network

- **Description**: Beta Network powers decentralized applications for the metaverse.
- **Primary Tag**: Ethereum
- **Followers**: 8,000
- **Website**: [betanetwork.com](https://betanetwork.com)
- **Socials**:
  - [Twitter](https://twitter.com/betanetwork)
  - [Discord](https://discord.gg/betanetwork)
  - [Telegram](https://t.me/betanetwork)
- **Apps**:
  - iOS: [Beta Network](https://apps.apple.com/app/betanetwork)
- **Created At**: November 9, 2024
- **Posts**: Post4, Post5, Post6

![Beta Network Logo](https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg)
    '''),
  Project(
      id: 'project3',
      name: 'BlocNet',
      logo:
          'https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg',
      description: 'Top community update/networking mobile application.',
      primaryTag: PrimaryTag.ethereum,
      followersCount: 8000,
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
      createdAt: DateTime.parse('2020-05-20'),
      postIds: {'post7', 'post8'},
      details: '''
# BlocNet

- **Description**: Top community update/networking mobile application.
- **Primary Tag**: Ethereum
- **Followers**: 8,000
- **Website**: [blocnet.com](https://blocnet.com)
- **Socials**:
  - [Twitter](https://twitter.com/blocnet)
  - [Discord](https://discord.gg/blocnet)
  - [Telegram](https://t.me/blocnet)
- **Apps**:
  - iOS: [BlocNet](https://apps.apple.com/app/blocnet)
- **Created At**: May 20, 2020
- **Posts**: Post7, Post8

![BlocNet Logo](https://pbs.twimg.com/profile_images/1642449081371959297/YlF36jXl_400x400.jpg)
    '''),
];
