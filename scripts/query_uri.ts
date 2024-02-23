import { ethers } from 'hardhat';



(async () => {
  let [signer] = await ethers.getSigners();

  const factory = await ethers.getContractAt(
    "nftTemplate",
    "0xeE9C1a31A5cf39799e492d70DF0E357740009eB5"
  );

  console.log("Minting NFT...")

  console.log(await factory.tokenURI(signer.address));
})()
