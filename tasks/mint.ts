import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";


const main = async (args: any, hre: HardhatRuntimeEnvironment) => {
  const [signer] = await hre.ethers.getSigners();

  const factory = await hre.ethers.getContractFactory("Launchpad");
  const contract = factory.attach(args.contract);

  const tx = await contract.connect(signer).mint(args.id, 1);

  const receipt = await tx.wait();
  const event = receipt.events?.find((event: any) => event.event === "Mint");
  const nftId = event?.args?.amount.toString();

  console.log(`🔑 Using account: ${signer.address}\n`);
  console.log(`✅ "mint" transaction has been broadcasted to ${hre.network.name}
📝 Transaction hash: ${receipt.transactionHash}
🌠 Minted NFT ID: ${nftId}
`);
};

task("mint", "Mint a new NFT.", main)
  .addParam("contract", "Contract address")
  .addParam("id", "Launchpad Id")
  .addFlag("json", "Output JSON");

