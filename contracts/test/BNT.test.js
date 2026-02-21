const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BNT", function () {
  async function deployFixture() {
    const [owner, treasury, other] = await ethers.getSigners();
    const BNT = await ethers.getContractFactory("BNT");
    const totalSupply = ethers.parseUnits("1000000", 18);
    const token = await BNT.deploy(treasury.address, totalSupply);
    await token.waitForDeployment();
    return { token, owner, treasury, other, totalSupply };
  }

  it("mints full initial supply to treasury", async function () {
    const { token, treasury, totalSupply } = await deployFixture();
    expect(await token.totalSupply()).to.equal(totalSupply);
    expect(await token.balanceOf(treasury.address)).to.equal(totalSupply);
    expect(await token.name()).to.equal("Blocnet Token");
    expect(await token.symbol()).to.equal("BNT");
  });

  it("reverts when treasury is zero address", async function () {
    const BNT = await ethers.getContractFactory("BNT");
    await expect(BNT.deploy(ethers.ZeroAddress, 1n)).to.be.revertedWith(
      "treasury is required",
    );
  });

  it("reverts when initial supply is zero", async function () {
    const [, treasury] = await ethers.getSigners();
    const BNT = await ethers.getContractFactory("BNT");
    await expect(BNT.deploy(treasury.address, 0n)).to.be.revertedWith(
      "supply must be > 0",
    );
  });
});
