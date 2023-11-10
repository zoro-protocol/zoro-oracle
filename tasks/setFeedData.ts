import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { task } from "hardhat/config";
import { Wallet } from "zksync-web3";
import { getChainId } from "./utils";
import { getMainAddresses } from "./addresses";
import { FeedData, FeedDataConfig, SetFeedDataParams } from "./types";
import feedData from "../deploy/feeds.json";

export async function main(
  hre: HardhatRuntimeEnvironment,
  asset: string
): Promise<void> {
  const wallet: Wallet = await hre.getZkWallet();

  const chainId: number = getChainId(hre);

  const oracleAddress: string = getMainAddresses()["oracle"][chainId];

  const oracle: ethers.Contract = await hre.ethers.getContractAt(
    "src/PriceOracle.sol:PriceOracle",
    oracleAddress,
    wallet
  );

  const { feed, decimals, underlyingDecimals }: FeedData = (feedData as FeedDataConfig)[asset.toLowerCase()];

  const tx = await oracle.setFeedData(feed, decimals, underlyingDecimals);
  tx.wait();
}

task(
  "setFeedData",
  "Configure a feed for the oracle"
)
  .addPositionalParam("asset", "Symbol of underlying asset")
  .setAction(
    async (
      { asset }: SetFeedDataParams,
      hre: HardhatRuntimeEnvironment
    ): Promise<void> => {
      console.log("Configuring price feed...");

      await main(hre, asset);
    }
  );
