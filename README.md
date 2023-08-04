[![codecov](https://codecov.io/gh/zoro-protocol/zoro-oracle/branch/main/graph/badge.svg?token=8L02N785BU)](https://codecov.io/gh/zoro-protocol/zoro-oracle)

# Zoro Oracle

## Installation

1. Install project dependencies.

```bash
forge install
npm install
```

2. Create a `.env` file in the project root directory with the following:

```bash
ETH_KEYSTORE=<path to the keystore used to sign transactions>
```

I know everyone loves raw dogging private keys in their .env, but please no. Show me a wallet that stores your private keys unencrypted and hasn't been hacked. I don't care if it's local tests with a fresh Metamask account, it sets a bad precendent.

## Test

```bash
forge test -vvv
```

## Deploy

1. Run the deployment script. The contracts will automatically be verified.

```bash
npx hardhat deploy-zksync --network zkTestnet
```

2. Enter the password to your keystore when prompted.
