import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { type BigNumber } from "ethers";
import { type Contract, type Wallet } from "zksync-web3";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { type OracleConstructorArgs } from "../types";

export default async function (hre: HardhatRuntimeEnvironment): Promise<void> {
  const wallet: Wallet = await hre.getZkWallet();

  const deployer: Deployer = new Deployer(hre, wallet);

  const artifact = await deployer.loadArtifact(
    "src/PriceOracle.sol:PriceOracle",
  );

  const pricePublisher: string = wallet.address;
  const feedAdmin: string = wallet.address;
  const defaultAdmin: string = wallet.address;
  const args: OracleConstructorArgs = [pricePublisher, feedAdmin, defaultAdmin];

  // Estimate contract deployment fee
  const deploymentFee: BigNumber = await deployer.estimateDeployFee(
    artifact,
    args,
  );

  const parsedFee: string = hre.ethers.utils.formatEther(
    deploymentFee.toString(),
  );
  console.log(`The deployment is estimated to cost ${parsedFee} ETH`);

  const contract: Contract = await deployer.deploy(artifact, args);

  // obtain the Constructor Arguments
  console.log("constructor args: ", contract.interface.encodeDeploy(args));

  // Show the contract info
  const contractAddress: string = contract.address;
  console.log(`${artifact.contractName} was deployed to ${contractAddress}`);

  if ("verifyURL" in hre.network.config) {
    // Verify contract programmatically
    //
    // Contract MUST be fully qualified name (e.g. path/sourceName:contractName)
    const contractFullyQualifedName = "src/PriceOracle.sol:PriceOracle";
    const verificationId: number = await hre.run("verify:verify", {
      address: contractAddress,
      contract: contractFullyQualifedName,
      constructorArguments: args,
      bytecode: artifact.bytecode,
    });
    console.log(
      `${contractFullyQualifedName} verified! VerificationId: ${verificationId}`,
    );
  }
}
