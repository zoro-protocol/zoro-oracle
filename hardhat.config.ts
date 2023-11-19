import "dotenv/config";
import { HardhatUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-foundry";
import "@matterlabs/hardhat-zksync-toolbox";
import "./zk-wallet";

import richWallets from "./rich-wallets.json";

const { ETH_KEYSTORE = "" } = process.env;

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  zksolc: {
    version: "1.3.13",
  },
  networks: {
    zkLocal: {
      url: "http://localhost:3050",
      ethNetwork: "http://localhost:8545",
      chainId: 270,
      zksync: true,
      zkWallet: {
        privateKey: richWallets[0].privateKey,
      },
    },
    zkTestnet: {
      url: "https://testnet.era.zksync.dev", // The testnet RPC URL of zkSync Era network.
      ethNetwork: "goerli", // The Ethereum Web3 RPC URL, or the identifier of the network (e.g. `mainnet` or `goerli`)
      chainId: 280,
      zksync: true,
      verifyURL:
        "https://zksync2-testnet-explorer.zksync.dev/contract_verification", // Verification endpoint
      zkWallet: {
        keystore: ETH_KEYSTORE,
      },
    },
  },
  defaultNetwork: "zkLocal", // optional (if not set, use '--network zkTestnet')
};

import "./tasks/setFeedData";
import "./tasks/setCTokenFeed";

export default config;
