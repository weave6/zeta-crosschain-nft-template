import { ethers } from "ethers";
import { task, types } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getSupportedNetworks } from "@zetachain/networks";
import { network } from "hardhat";

const main = async (args: any, hre: HardhatRuntimeEnvironment) => {
  const networks = args.networks.split(",");
  const contracts: { [key: string]: string } = {};

  await Promise.all(
    networks.map(async (networkName: string, index: number) => {
      const launchpad = await deployContract(
        hre,
        networkName,
        args.json,
        args.gasLimit
      );

      await deployNFT(hre, networkName, args.json, args.gasLimit, launchpad);

    })
  );

  if (args.json) {
    console.log(JSON.stringify(contracts, null, 2));
  }
};

const initWallet = (hre: HardhatRuntimeEnvironment, networkName: string) => {
  const { url, accounts } = hre.config.networks[networkName] as any;
  const provider = new ethers.providers.JsonRpcProvider(url);
  if (networkName == "localhost") {
    const wallet = new ethers.Wallet(accounts[0], provider);
    return wallet;
  } else {
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY as string, provider);
    return wallet;
  }
};
const deployNFT = async (
  hre: HardhatRuntimeEnvironment,
  networkName: string,
  json: boolean = false,
  gasLimit: number,
  launchpadAddress: String
) => {

  const wallet = initWallet(hre, networkName);
  const { abi, bytecode } = await hre.artifacts.readArtifact("WeavePasscard");
  const weave_factory = new ethers.ContractFactory(abi, bytecode, wallet);
  const weave_contract = await weave_factory.deploy(launchpadAddress, { gasLimit });

  await weave_contract.deployed();
  if (!json) {
    console.log(`
🚀 Successfully deployed contract on ${networkName}.
📜 NFT Contract address: ${weave_contract.address}`);
  }
}
const deployContract = async (
  hre: HardhatRuntimeEnvironment,
  networkName: string,
  json: boolean = false,
  gasLimit: number
) => {
  const wallet = initWallet(hre, networkName);

  const { abi, bytecode } = await hre.artifacts.readArtifact("Launchpad");
  const factory = new ethers.ContractFactory(abi, bytecode, wallet);
  const contract = await factory.deploy({ gasLimit });
  await contract.deployed();

  if (!json) {
    console.log(`
🚀 Successfully deployed contract on ${networkName}.
📜 Launchpad Contract address: ${contract.address}`);
  }

  return contract.address;
};

task("deploy", "Deploy the contract", main)
  .addParam(
    "networks",
    `Comma separated list of networks to deploy to (e.g. ${getSupportedNetworks(
      "ccm"
    )})`
  )
  .addOptionalParam("gasLimit", "Gas limit", 10000000, types.int)
  .addFlag("json", "Output JSON");
