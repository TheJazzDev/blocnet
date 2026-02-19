require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();

const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: '0.8.24',
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },
  networks: {
    bscTestnet: {
      url:
        process.env.BSC_TESTNET_RPC_URL ??
        'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      accounts: deployerPrivateKey ? [deployerPrivateKey] : [],
    },
    bscMainnet: {
      url: process.env.BSC_MAINNET_RPC_URL ?? 'https://bsc-dataseed.binance.org',
      chainId: 56,
      accounts: deployerPrivateKey ? [deployerPrivateKey] : [],
    },
  },
  etherscan: {
    // Etherscan V2 requires a single API key value.
    // Keep BSCSCAN_API_KEY as fallback for existing local env files.
    apiKey: process.env.ETHERSCAN_API_KEY ?? process.env.BSCSCAN_API_KEY ?? '',
  },
};
