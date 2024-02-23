import { ethers } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { utils } from "ethers";

function eth(n: number) {
  return utils.parseEther(n.toString()).toString();
}

describe("Launchpad", function () {
  const launchpadId = 0;

  let launchpad: any;
  let nft: any;

  let sender: SignerWithAddress,
    bob: SignerWithAddress,
    alice: SignerWithAddress,
    jack: SignerWithAddress,
    mark: SignerWithAddress,
    ada: SignerWithAddress,
    joe: SignerWithAddress,
    lily: SignerWithAddress,
    lucy: SignerWithAddress;

  beforeEach("init", async function () {
    [sender, bob, alice, jack, mark, ada, joe, lily, lucy] =
      await ethers.getSigners();

    const launch = await ethers.getContractFactory("Launchpad");
    launchpad = await launch.deploy();
    await launchpad.deployed();

    const nft_dep = await ethers.getContractFactory("WeavePasscard");
    nft = await nft_dep.deploy(launchpad.address);
    await nft.deployed();
    //await launchpad.initialize(sender.address)
    await launchpad.createLaunchpad(
      nft.address,
      sender.address,
      eth(0),
      280,
      1,
      0,
      Date.now() + 86400000,
      false,
      false
    );
  });

  it("should deploy the Launchpad contract", async function () {
    expect(launchpad.address).to.not.equal(0);
  });

  it("should allow whitelisted users to mint tokens", async function () {
    await launchpad.connect(sender).switchOnlyWhiteList(launchpadId);
    // Add sender to the whitelist
    await launchpad.addWhitelistUser(launchpadId, sender.address);

    // Mint tokens
    const amount = 1;
    await launchpad.connect(sender).mint(launchpadId, amount);

    // Check the balance of the sender
    const balance = await nft.balanceOf(sender.address);
    expect(balance).to.equal(amount);

    await expect(
      launchpad.connect(sender).mint(launchpadId, amount)
    ).to.be.revertedWith("Amount is greater than max amount per wallet");
  });

  it("should not allow non-whitelisted users to mint tokens", async function () {
    // Attempt to mint tokens without being whitelisted
    const amount = 1;
    await launchpad.connect(sender).switchOnlyWhiteList(launchpadId);

    await expect(
      launchpad.connect(bob).mint(launchpadId, amount)
    ).to.be.revertedWith("User is not whitelisted");

    // Check the balance of the non-whitelisted user (should be 0)
    const balance = await nft.balanceOf(sender.address);
    expect(balance).to.equal(0);
  });

  it("should emit events when minting tokens", async function () {
    // Add sender to the whitelist
    await launchpad.addWhitelistUser(launchpadId, sender.address);

    // Mint tokens
    const amount = 1;
    await expect(launchpad.connect(sender).mint(launchpadId, amount))
      .to.emit(launchpad, "Mint")
      .withArgs(launchpadId, sender.address, 1);
  });

  it("should prevent minting tokens with invalid inputs", async function () {
    // Add sender to the whitelist
    await launchpad.addWhitelistUser(launchpadId, sender.address);

    // Attempt to mint tokens with invalid inputs
    const invalidTokenId = 0;
    const invalidAmount = 0;
    await expect(launchpad.connect(sender).mint(invalidTokenId, invalidAmount))
      .to.be.reverted;
  });

  it("should allow the owner to add and remove whitelist users", async function () {
    // Add a new user to the whitelist
    await launchpad.connect(sender).addWhitelistUser(launchpadId, bob.address);

    // Check if the new user is in the whitelist
    expect(await launchpad.isUserWhitelisted(launchpadId, bob.address)).to.be
      .true;

    // Remove the user from the whitelist
    await launchpad
      .connect(sender)
      .removeWhitelistUser(launchpadId, bob.address);

    // Check if the user is no longer in the whitelist
    expect(await launchpad.isUserWhitelisted(launchpadId, bob.address)).to.be
      .false;
  });

  it("should prevent non-owner from adding or removing whitelist users", async function () {
    // Attempt to add a new user to the whitelist as a non-owner
    await expect(
      launchpad.connect(bob).addWhitelistUser(launchpadId, alice.address)
    ).to.be.reverted;

    // Attempt to remove a user from the whitelist as a non-owner
    await expect(
      launchpad.connect(bob).removeWhitelistUser(launchpadId, alice.address)
    ).to.be.reverted;
  });

  it("should take amount when minted", async function () {
    await launchpad
      .connect(sender)
      .updateLaunchpad(
        launchpadId,
        nft.address,
        sender.address,
        eth(10),
        280,
        1,
        0,
        Date.now() + 86400000,
        false
      );
    // Mint tokens
    const amount = 1;
    await launchpad
      .connect(sender)
      .mint(launchpadId, amount, { value: eth(10) });

    // Check the balance of the sender
    const balance = await nft.balanceOf(sender.address);
    expect(balance).to.equal(amount);
  });
});
