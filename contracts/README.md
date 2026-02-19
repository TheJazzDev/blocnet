# Blocnet BNT Contracts

## Setup

1. Copy `.env.example` to `.env` and fill required values.
2. Set `ETHERSCAN_API_KEY` (Etherscan V2 key used for BSC verify as well).
3. Install dependencies:

```bash
npm install
```

## Deploy

```bash
npm run deploy:testnet
npm run verify:testnet
```

For mainnet:

```bash
npm run deploy:mainnet
npm run verify:mainnet
```

## Export ABI + addresses for backend

After compile/deploy:

```bash
npm run export:artifact
```

This writes:

- `../backend/src/wallet/artifacts/bnt.abi.json`
- `../backend/src/wallet/artifacts/bnt.addresses.json`
