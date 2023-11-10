import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { task } from "hardhat/config";
import { Wallet } from "zksync-web3";
import { getChainId } from "./utils";
import { getMainAddresses, getCTokenAddresses } from "./addresses";
import { FeedDataConfig, SetCTokenFeedParams } from "./types";
import feedData from "../deploy/feeds.json";

export async function main(
  hre: HardhatRuntimeEnvironment,
  cToken: string,
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

  const { feed }: { feed: string } = (feedData as FeedDataConfig)[asset.toLowerCase()];

  const cTokenAddress = getCTokenAddresses()[cToken][chainId];

  const tx = await oracle.setCTokenFeed(cTokenAddress, feed);
  tx.wait();
}

task(
  "setCTokenFeed",
  "Map a CToken to a price feed"
)
  .addPositionalParam("cToken", "Symbol of underlying asset for CToken")
  .addPositionalParam("asset", "Symbol of underlying asset")
  .setAction(
    async (
      { cToken, asset }: SetCTokenFeedParams,
      hre: HardhatRuntimeEnvironment
    ): Promise<void> => {
      console.log("Configuring price feed...");

      await main(hre, cToken, asset);
    }
  );
