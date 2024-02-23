import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";


const main = async (args: any, hre: HardhatRuntimeEnvironment) => {
  const [signer] = await hre.ethers.getSigners();

  const factory = await hre.ethers.getContractFactory("Launchpad");
  const contract = factory.attach(args.contract);

  const tx = await contract.connect(signer).addWhitelistUsers(args.id, [
    "0x6Acc4B7fA83CD618795cA074828B77AC220E7e5a",
    "0xC9401A6FF63124D4eFbb9Da876a278ee2dE5Bb1F",
    "0x7aC1af6E87D067EC5687b613208049Cd7A409941",
    "0x74D31218891D46f861aF1CF97612e39949C0A2fb",
    "0xC9f9D9176DE7BadB9b0f5a0B9F185b67f4FAa534"
  ]);


  const receipt = await tx.wait();

  console.log(`🔑 Using account: ${signer.address}\n`);
  console.log(`✅ "add white list" transaction has been broadcasted to ${hre.network.name}
📝 Transaction hash: ${receipt.transactionHash}
`);
};

task("addWl", "Add Wl to contract", main)
  .addParam("contract", "Contract address")
  .addParam("id", "Launchpad Id")
  .addFlag("json", "Output JSON");
