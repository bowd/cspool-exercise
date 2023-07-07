import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("ConstantSumPool", () => {
  async function deployPool() {
    const [owner, otherAccount] = await ethers.getSigners();
    const ConstantSumPool = await ethers.getContractFactory("ConstantSumPool");
    const ERC20 = await ethers.getContractFactory("tERC20");
    const asset0 = await ERC20.deploy("Asset0", "A0");
    const asset1 = await ERC20.deploy("Asset1", "A1");
    const pool = await ConstantSumPool.deploy(
      asset0,
      asset1,
      ethers.parseEther("0.01")
    );

    await asset0.mint(await owner.getAddress(), 1e12);
    await asset1.mint(await owner.getAddress(), 1e12);
    await asset0.approve(await pool.getAddress(), 1e12);
    await asset1.approve(await pool.getAddress(), 1e12);

    return { owner, otherAccount, pool, asset0, asset1 };
  }

  describe("Deployment", () => {
    it("Should set the assets and fee", async () => {
      const { pool, asset0, asset1 } = await loadFixture(deployPool);
      expect(await pool.asset0()).to.equal(await asset0.getAddress());
      expect(await pool.asset1()).to.equal(await asset1.getAddress());
      expect(await pool.swapFee()).to.equal(ethers.parseEther("0.01"));
    });
  });

  describe("Deposit", () => {
    it("Should update buckets", async () => {
      const { pool } = await loadFixture(deployPool);

      await pool.deposit(1e10, 1e10);
      expect(await pool.bucket0()).to.equal(1e10);
      expect(await pool.bucket1()).to.equal(1e10);
    });
  });

  describe("Swap", () => {
    it("Should swap with fee", async () => {
      const { pool, asset0, asset1, owner } = await loadFixture(deployPool);

      await pool.deposit(1e10, 1e10);

      let balanceBefore = await asset1.balanceOf(await owner.getAddress());
      await pool.swapInFixed(await asset0.getAddress(), 1e9);
      let balanceAfter = await asset1.balanceOf(await owner.getAddress());
      expect(balanceAfter - balanceBefore).to.equal(999e6);
      balanceBefore = balanceAfter;
      await pool.swapInFixed(await asset1.getAddress(), 1e9);
      balanceAfter = await asset1.balanceOf(await owner.getAddress());
      expect(balanceAfter - balanceBefore).to.equal(999e6);

      expect(await pool.bucket0()).to.equal(12e9);
      expect(await pool.bucket1()).to.equal(98e9 + 2e6);
    });
  });
});
