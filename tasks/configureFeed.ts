import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { task } from "hardhat/config";
import { Wallet } from "zksync-web3";
import { Feed, FeedDataConfig, ConfigureFeedParams } from "../scripts/types";
import feedData from "../deploy/feeds.json";

export async function main(
  hre: HardhatRuntimeEnvironment,
  feedId: string
): Promise<void> {
  const wallet: Wallet = await hre.getZkWallet();

  const oracleAddress: string = hre.getAddress("oracle", "base");

  const oracle: ethers.Contract = await hre.ethers.getContractAt(
    "src/BasePriceOracle.sol:BasePriceOracle",
    oracleAddress,
    wallet
  );

  const { feed, decimals, underlyingDecimals }: Feed = (feedData as FeedDataConfig)[feedId.toLowerCase()];

  const tx = await oracle.configureFeed(feed, decimals, underlyingDecimals);
  tx.wait();
}

task(
  "configureFeed",
  "Configure a feed for the oracle"
)
  .addPositionalParam("feedId", "ID for the feed in feeds.json")
  .setAction(
    async (
      { feedId }: ConfigureFeedParams,
      hre: HardhatRuntimeEnvironment
    ): Promise<void> => {
      console.log("Configuring price feed...");

      await main(hre, feedId);
    }
  );
