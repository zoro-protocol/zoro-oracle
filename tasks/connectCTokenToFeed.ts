import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { task } from "hardhat/config";
import { Wallet } from "zksync-web3";
import { getChainId } from "./utils";
import { getMainAddresses, getCTokenAddresses } from "./addresses";
import { FeedDataConfig, ConnectCTokenToFeedParams } from "./types";
import feedData from "../deploy/feeds.json";

export async function main(
  hre: HardhatRuntimeEnvironment,
  cTokenId: string,
  feedId: string
): Promise<void> {
  const wallet: Wallet = await hre.getZkWallet();

  const chainId: number = getChainId(hre);

  const oracleAddress: string = getMainAddresses()["oracle"][chainId];

  const oracle: ethers.Contract = await hre.ethers.getContractAt(
    "src/BasePriceOracle.sol:BasePriceOracle",
    oracleAddress,
    wallet
  );

  const { feed }: { feed: string } = (feedData as FeedDataConfig)[feedId.toLowerCase()];

  const cToken = getCTokenAddresses()[cTokenId][chainId];

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
