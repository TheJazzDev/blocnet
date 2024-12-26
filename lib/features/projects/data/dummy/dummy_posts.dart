import '../models/post_model.dart';
import '../models/secondary_tag_model.dart';
import '../models/priority_model.dart';

List<Post> dummyPosts = [
  Post(
    postId: 'post1',
    projectId: 'project1',
    adminId: 'admin1',
    secondaryTags: [
      SecondaryTag.airdrops,
      SecondaryTag.mining,
      SecondaryTag.nft,
      SecondaryTag.launching,
      SecondaryTag.partnership,
      SecondaryTag.metaverse
    ],
    title:
        'Critical exploit found in Bitcoin wallet. Move your funds immediately!',
    description:
        'Due to unforeseen technical issues, Bitcoin has extended the vesting period for its tokens. The unlock date is now scheduled for December 15. Be sure to adjust your trading strategies in light of this delay.',
    priority: Priority.mid,
    createdAt: DateTime.parse('2022-01-23'),
    lastEditedAt: DateTime.parse('2024-05-20'),
    content: """
## Overview

A major vulnerability has been discovered in the **BitcoinSecure** wallet, potentially exposing millions of wallets to malicious actors. This exploit allows hackers to bypass the encryption layer, gaining unauthorized access to funds. **If you are using this wallet, move your Bitcoin immediately to a secure alternative!**

## Key Details of the Exploit

### 1. What Happened?
- Researchers at **BlockchainSecLabs** identified a critical bug in the wallet's encryption mechanism.

### 2. Who’s Affected?
- Any user with funds stored in the affected wallet.

### 3. Potential Impact:
- Hackers could drain wallet balances remotely if the exploit is not addressed promptly.

## What Should You Do?

### 1. Move Your Funds:
- Recommended alternatives: **Ledger**, **Trezor**, or **Trust Wallet**.
- Follow [this step-by-step guide](#) to transfer your Bitcoin securely.

### 2. Avoid Phishing Attacks:
- Do not click on unsolicited emails or links claiming to fix the wallet issue.

### 3. Update for Protection:
- The BitcoinSecure team is working on a patch. Monitor their [website](https://example.com) for updates.

## Related Resources
- [Top 10 Secure Wallets for 2024](#)
- [How to Protect Your Bitcoin From Hacks](#)
""",
  ),
  Post(
    postId: 'post2',
    projectId: 'project2',
    adminId: 'admin2',
    secondaryTags: [
      SecondaryTag.partnership,
      SecondaryTag.staking,
      SecondaryTag.mining,
      SecondaryTag.airdrops,
      SecondaryTag.governance,
    ],
    title: 'New Ethereum update rolling out next week!',
    description:
        'Ethereum developers will be launching a new update next week to enhance scalability.',
    priority: Priority.high,
    createdAt: DateTime.parse('2024-18-20'),
    lastEditedAt: DateTime.now(),
    content: """
## Overview

A major vulnerability has been discovered in the **BitcoinSecure** wallet, potentially exposing millions of wallets to malicious actors. This exploit allows hackers to bypass the encryption layer, gaining unauthorized access to funds. **If you are using this wallet, move your Bitcoin immediately to a secure alternative!**

## Key Details of the Exploit

### 1. What Happened?
- Researchers at **BlockchainSecLabs** identified a critical bug in the wallet's encryption mechanism.

### 2. Who’s Affected?
- Any user with funds stored in the affected wallet.

### 3. Potential Impact:
- Hackers could drain wallet balances remotely if the exploit is not addressed promptly.

## What Should You Do?

### 1. Move Your Funds:
- Recommended alternatives: **Ledger**, **Trezor**, or **Trust Wallet**.
- Follow [this step-by-step guide](#) to transfer your Bitcoin securely.

### 2. Avoid Phishing Attacks:
- Do not click on unsolicited emails or links claiming to fix the wallet issue.

### 3. Update for Protection:
- The BitcoinSecure team is working on a patch. Monitor their [website](https://example.com) for updates.

## Related Resources
- [Top 10 Secure Wallets for 2024](#)
- [How to Protect Your Bitcoin From Hacks](#)
""",
  ),
  Post(
    postId: 'post3',
    projectId: 'project3',
    adminId: 'admin3',
    secondaryTags: [
      SecondaryTag.governance,
      SecondaryTag.nft,
      SecondaryTag.partnership,
      SecondaryTag.security,
      SecondaryTag.icoIdo,
      SecondaryTag.governance
    ],
    title: 'SpaceX mission to Mars launches next year!',
    description:
        'SpaceX announces plans for the first manned mission to Mars. Exciting times ahead!',
    priority: Priority.high,
    createdAt: DateTime.parse('2015-06-22'),
    lastEditedAt: DateTime.parse('2021-12-03'),
    content: """
## Overview

A major vulnerability has been discovered in the **BitcoinSecure** wallet, potentially exposing millions of wallets to malicious actors. This exploit allows hackers to bypass the encryption layer, gaining unauthorized access to funds. **If you are using this wallet, move your Bitcoin immediately to a secure alternative!**

## Key Details of the Exploit

### 1. What Happened?
- Researchers at **BlockchainSecLabs** identified a critical bug in the wallet's encryption mechanism.

### 2. Who’s Affected?
- Any user with funds stored in the affected wallet.

### 3. Potential Impact:
- Hackers could drain wallet balances remotely if the exploit is not addressed promptly.

## What Should You Do?

### 1. Move Your Funds:
- Recommended alternatives: **Ledger**, **Trezor**, or **Trust Wallet**.
- Follow [this step-by-step guide](#) to transfer your Bitcoin securely.

### 2. Avoid Phishing Attacks:
- Do not click on unsolicited emails or links claiming to fix the wallet issue.

### 3. Update for Protection:
- The BitcoinSecure team is working on a patch. Monitor their [website](https://example.com) for updates.

## Related Resources
- [Top 10 Secure Wallets for 2024](#)
- [How to Protect Your Bitcoin From Hacks](#)
""",
  ),
  Post(
    postId: 'post4',
    projectId: 'project3',
    adminId: 'admin3',
    secondaryTags: [
      SecondaryTag.nft,
      SecondaryTag.metaverse,
      SecondaryTag.gaming,
    ],
    title: 'Meta introduces new AR glasses!',
    description:
        'Meta’s new AR glasses revolutionize user interaction with the digital world.',
    priority: Priority.mid,
    createdAt: DateTime.parse('2022-01-23'),
    lastEditedAt: null,
    content: """
## Overview

A major vulnerability has been discovered in the **BitcoinSecure** wallet, potentially exposing millions of wallets to malicious actors. This exploit allows hackers to bypass the encryption layer, gaining unauthorized access to funds. **If you are using this wallet, move your Bitcoin immediately to a secure alternative!**

## Key Details of the Exploit

### 1. What Happened?
- Researchers at **BlockchainSecLabs** identified a critical bug in the wallet's encryption mechanism.

### 2. Who’s Affected?
- Any user with funds stored in the affected wallet.

### 3. Potential Impact:
- Hackers could drain wallet balances remotely if the exploit is not addressed promptly.

## What Should You Do?

### 1. Move Your Funds:
- Recommended alternatives: **Ledger**, **Trezor**, or **Trust Wallet**.
- Follow [this step-by-step guide](#) to transfer your Bitcoin securely.

### 2. Avoid Phishing Attacks:
- Do not click on unsolicited emails or links claiming to fix the wallet issue.

### 3. Update for Protection:
- The BitcoinSecure team is working on a patch. Monitor their [website](https://example.com) for updates.

## Related Resources
- [Top 10 Secure Wallets for 2024](#)
- [How to Protect Your Bitcoin From Hacks](#)
""",
  ),
  Post(
    postId: 'post5',
    projectId: 'project1',
    adminId: 'admin3',
    secondaryTags: [SecondaryTag.wallet, SecondaryTag.security],
    title: 'Bitcoin wallet breach alert!',
    description:
        'A critical security flaw in Bitcoin wallets has been discovered. Immediate update required.',
    priority: Priority.mid,
    createdAt: DateTime.parse('2019-14-06'),
    lastEditedAt: DateTime.parse('2021-10-09'),
    content: """
## Overview

A major vulnerability has been discovered in the **BitcoinSecure** wallet, potentially exposing millions of wallets to malicious actors. This exploit allows hackers to bypass the encryption layer, gaining unauthorized access to funds. **If you are using this wallet, move your Bitcoin immediately to a secure alternative!**

## Key Details of the Exploit

### 1. What Happened?
- Researchers at **BlockchainSecLabs** identified a critical bug in the wallet's encryption mechanism.

### 2. Who’s Affected?
- Any user with funds stored in the affected wallet.

### 3. Potential Impact:
- Hackers could drain wallet balances remotely if the exploit is not addressed promptly.

## What Should You Do?

### 1. Move Your Funds:
- Recommended alternatives: **Ledger**, **Trezor**, or **Trust Wallet**.
- Follow [this step-by-step guide](#) to transfer your Bitcoin securely.

### 2. Avoid Phishing Attacks:
- Do not click on unsolicited emails or links claiming to fix the wallet issue.

### 3. Update for Protection:
- The BitcoinSecure team is working on a patch. Monitor their [website](https://example.com) for updates.

## Related Resources
- [Top 10 Secure Wallets for 2024](#)
- [How to Protect Your Bitcoin From Hacks](#)
""",
  ),
  Post(
    postId: 'post6',
    projectId: 'project1',
    adminId: 'admin1',
    secondaryTags: [SecondaryTag.staking, SecondaryTag.mining],
    title: 'AI revolution in blockchain technology.',
    description:
        'AI is rapidly being integrated into blockchain for better scalability and automation.',
    priority: Priority.low,
    createdAt: DateTime.parse('2022-01-23'),
    lastEditedAt: null,
    content: """
## Overview

A major vulnerability has been discovered in the **BitcoinSecure** wallet, potentially exposing millions of wallets to malicious actors. This exploit allows hackers to bypass the encryption layer, gaining unauthorized access to funds. **If you are using this wallet, move your Bitcoin immediately to a secure alternative!**

## Key Details of the Exploit

### 1. What Happened?
- Researchers at **BlockchainSecLabs** identified a critical bug in the wallet's encryption mechanism.

### 2. Who’s Affected?
- Any user with funds stored in the affected wallet.

### 3. Potential Impact:
- Hackers could drain wallet balances remotely if the exploit is not addressed promptly.

## What Should You Do?

### 1. Move Your Funds:
- Recommended alternatives: **Ledger**, **Trezor**, or **Trust Wallet**.
- Follow [this step-by-step guide](#) to transfer your Bitcoin securely.

### 2. Avoid Phishing Attacks:
- Do not click on unsolicited emails or links claiming to fix the wallet issue.

### 3. Update for Protection:
- The BitcoinSecure team is working on a patch. Monitor their [website](https://example.com) for updates.

## Related Resources
- [Top 10 Secure Wallets for 2024](#)
- [How to Protect Your Bitcoin From Hacks](#)
""",
  ),
  Post(
    postId: 'post7',
    projectId: 'project2',
    adminId: 'admin2',
    secondaryTags: [SecondaryTag.governance, SecondaryTag.nft],
    title: 'Ethereum 2.0 updates rolling out!',
    description:
        'Ethereum 2.0 upgrades are live, focusing on faster transactions and reduced gas fees.',
    priority: Priority.high,
    createdAt: DateTime.parse('2022-01-23'),
    lastEditedAt: null,
    content: """
## Overview

A major vulnerability has been discovered in the **BitcoinSecure** wallet, potentially exposing millions of wallets to malicious actors. This exploit allows hackers to bypass the encryption layer, gaining unauthorized access to funds. **If you are using this wallet, move your Bitcoin immediately to a secure alternative!**

## Key Details of the Exploit

### 1. What Happened?
- Researchers at **BlockchainSecLabs** identified a critical bug in the wallet's encryption mechanism.

### 2. Who’s Affected?
- Any user with funds stored in the affected wallet.

### 3. Potential Impact:
- Hackers could drain wallet balances remotely if the exploit is not addressed promptly.

## What Should You Do?

### 1. Move Your Funds:
- Recommended alternatives: **Ledger**, **Trezor**, or **Trust Wallet**.
- Follow [this step-by-step guide](#) to transfer your Bitcoin securely.

### 2. Avoid Phishing Attacks:
- Do not click on unsolicited emails or links claiming to fix the wallet issue.

### 3. Update for Protection:
- The BitcoinSecure team is working on a patch. Monitor their [website](https://example.com) for updates.

## Related Resources
- [Top 10 Secure Wallets for 2024](#)
- [How to Protect Your Bitcoin From Hacks](#)
""",
  ),
  Post(
    postId: 'post8',
    projectId: 'project1',
    adminId: 'admin1',
    secondaryTags: [SecondaryTag.tokenBurn, SecondaryTag.ido],
    title: 'Solana hits new milestone in transaction speeds.',
    description:
        'Solana is now processing over 65,000 transactions per second, making it a leader in blockchain scalability.',
    priority: Priority.low,
    createdAt: DateTime.parse('2022-01-23'),
    lastEditedAt: DateTime.parse('4018-08-29'),
    content: """
## Overview

A major vulnerability has been discovered in the **BitcoinSecure** wallet, potentially exposing millions of wallets to malicious actors. This exploit allows hackers to bypass the encryption layer, gaining unauthorized access to funds. **If you are using this wallet, move your Bitcoin immediately to a secure alternative!**

## Key Details of the Exploit

### 1. What Happened?
- Researchers at **BlockchainSecLabs** identified a critical bug in the wallet's encryption mechanism.

### 2. Who’s Affected?
- Any user with funds stored in the affected wallet.

### 3. Potential Impact:
- Hackers could drain wallet balances remotely if the exploit is not addressed promptly.

## What Should You Do?

### 1. Move Your Funds:
- Recommended alternatives: **Ledger**, **Trezor**, or **Trust Wallet**.
- Follow [this step-by-step guide](#) to transfer your Bitcoin securely.

### 2. Avoid Phishing Attacks:
- Do not click on unsolicited emails or links claiming to fix the wallet issue.

### 3. Update for Protection:
- The BitcoinSecure team is working on a patch. Monitor their [website](https://example.com) for updates.

## Related Resources
- [Top 10 Secure Wallets for 2024](#)
- [How to Protect Your Bitcoin From Hacks](#)
""",
  ),
];
