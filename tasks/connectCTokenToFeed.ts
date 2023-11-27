import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { task } from "hardhat/config";
import { Wallet } from "zksync-web3";
import { FeedDataConfig, ConnectCTokenToFeedParams } from "../scripts/types";
import feedData from "../deploy/feeds.json";

const cTokenAddresses = "../lib/zoro-protocol/zksync/deploy/addresses/zTokens.json";

export async function main(
  hre: HardhatRuntimeEnvironment,
  cTokenId: string,
  feedId: string
): Promise<void> {
  const wallet: Wallet = await hre.getZkWallet();

  const oracleAddress: string = hre.getAddress("oracle", "base");

  const oracle: ethers.Contract = await hre.ethers.getContractAt(
    "src/BasePriceOracle.sol:BasePriceOracle",
    oracleAddress,
    wallet
  );

  const { feed }: { feed: string } = (feedData as FeedDataConfig)[feedId.toLowerCase()];

  const cToken = hre.getAddress(cTokenAddresses, cTokenId);

  const tx = await oracle.connectCTokenToFeed(cToken, feed);
  tx.wait();
}

task(
  "connectCTokenToFeed",
  "Connect a CToken to a price feed"
)
  .addPositionalParam("cTokenId", "ID for the CToken in zTokens.json")
  .addPositionalParam("feedId", "ID for the feed in feeds.json")
  .setAction(
    async (
      { cTokenId, feedId }: ConnectCTokenToFeedParams,
      hre: HardhatRuntimeEnvironment
    ): Promise<void> => {
      console.log("Connecting CToken to price feed...");

      await main(hre, cTokenId, feedId);
    }
  );
