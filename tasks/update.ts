import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { utils } from "ethers";

function eth(n: number) {
  return utils.parseEther(n.toString()).toString();
}

const main = async (args: any, hre: HardhatRuntimeEnvironment) => {
  const [signer] = await hre.ethers.getSigners();

  const factory = await hre.ethers.getContractFactory("Launchpad");
  const launchpad = factory.attach(args.contract);

  const tx = await launchpad.updateLaunchpad(
    args.id,
    args.nftAddress,
    signer.address,
    eth(args.price),
    args.amount,
    args.maxPerWallet,
    args.start,//start time
    args.end,//end time
    args.wl, // while list ?
  );

  const receipt = await tx.wait();
  const event = receipt.events?.find((event: any) => event.event === "CreateLaunchpadEvent");
  console.log(event)
  const Id = event?.args?.launchpadId.toString();

  if (args.json) {
    console.log(Id);
  } else {
    console.log(`🔑 Using account: ${signer.address}\n`);
    console.log(`✅ "Update Launchpad: ${args.id}" transaction has been broadcasted to ${hre.network.name}
📝 Transaction hash: ${receipt.transactionHash}
🌠 Launchpad ID: ${Id}
`);
  }
};

task("updateLaunchpad", "Create new launchpad", main)
  .addParam("contract", "Contract address")
  .addParam("id", "ID of launchpad to update")
  .addParam("nftAddress", "NFT Contract address")
  .addParam("price", "PRICE in ETH")
  .addParam("amount", "amount in round")
  .addParam("maxPerWallet", "max per wallet")
  .addParam("start", "start time in unix timestamp (ms)")
  .addParam("end", "end time in unix timestamp (ms)")
  .addFlag("wl", "Private white listed mint")
  .addFlag("json", "Output JSON");
