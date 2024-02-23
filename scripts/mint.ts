import { ethers } from 'hardhat';



(async () => {
  let [signer] = await ethers.getSigners();

  const factory = await ethers.getContractAt(
    "nftTemplate",
    "0x25b3c9f5Bed71dDcE2Ed3c1C272A358E075d2971"
  );

  console.log("Minting NFT...")

  await factory.mint(signer.address);
})()
