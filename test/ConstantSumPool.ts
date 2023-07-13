import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { IERC20, TERC20__factory } from "../typechain-types";
import { ConstantSumPool__factory } from "../typechain-types";
import { expect } from "chai";
import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("ConstantSumPool", () => {
  async function deployPool() {
    const [owner, otherAccount] = await ethers.getSigners();
    const ConstantSumPool = (await ethers.getContractFactory(
      "ConstantSumPool"
    )) as ConstantSumPool__factory;
    const ERC20 = (await ethers.getContractFactory(
      "tERC20"
    )) as TERC20__factory;
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

  type Snapshot = {
    asset0: bigint;
    asset1: bigint;
  };

  const snapshotBalances = async (
    owner: HardhatEthersSigner,
    asset0: IERC20,
    asset1: IERC20
  ): Promise<Snapshot> => ({
    asset0: await asset0.balanceOf(await owner.getAddress()),
    asset1: await asset1.balanceOf(await owner.getAddress()),
  });

  const deltaBalances = (before: Snapshot, after: Snapshot): Snapshot => ({
    asset0: after.asset0 - before.asset0,
    asset1: after.asset1 - before.asset1,
  });

  describe("Swap", () => {
    it("Should swap fixed amount of asset0 for asset0 with fee", async () => {
      const { pool, asset0, asset1, owner } = await loadFixture(deployPool);
      await pool.deposit(1e10, 1e10);

      const balancesBefore = await snapshotBalances(owner, asset0, asset1);
      await pool.swapInFixed(await asset0.getAddress(), 1e9);
      const delta = deltaBalances(
        balancesBefore,
        await snapshotBalances(owner, asset0, asset1)
      );

      expect(delta.asset0).to.equal(-1e9);
      expect(delta.asset1).to.equal(999e6);
    });

    it("Should swap asset0 for fixed amount of asset1 with fee", async () => {
      const { pool, asset0, asset1, owner } = await loadFixture(deployPool);
      await pool.deposit(1e10, 1e10);

      const balancesBefore = await snapshotBalances(owner, asset0, asset1);
      await pool.swapOutFixed(await asset0.getAddress(), 1e9);
      const delta = deltaBalances(
        balancesBefore,
        await snapshotBalances(owner, asset0, asset1)
      );

      expect(delta.asset0).to.equal(-102e7);
      expect(delta.asset1).to.equal(1e9);
    });
  });
});
