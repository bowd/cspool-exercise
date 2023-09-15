// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import "openzeppelin/token/ERC20/ERC20.sol";

import { ConstantSumPool} from "../src/ConstantSumPool.sol";

contract USDC is ERC20 {
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

  function decimals() override public pure returns (uint8) {
    return 6;
  }
}

contract PoolTest is Test {
  ConstantSumPool public pool;
  ERC20 asset0;
  ERC20 asset1;

  function setUp() public {
    asset0 = new ERC20("asset0", "A0");
    asset1 = new ERC20("asset1", "A1");
    vm.label(address(asset0), "asset0");
    vm.label(address(asset1), "asset1");

    pool = new ConstantSumPool(address(asset0), address(asset1), 1e15);
  }

  function deposit() public {
    deal(address(asset0), address(this), 10e22);
    deal(address(asset1), address(this), 10e22);

    asset0.approve(address(pool), 10e22);
    asset1.approve(address(pool), 10e22);
    pool.deposit(10e22, 10e22);
  }

  function testDeposit() public {
    deposit();
    assertEq(pool.bucket0(), 10e22);
    assertEq(pool.bucket1(), 10e22);
  }

  function test_swapFixedAmountInWithFee() public {
    deposit();

    deal(address(asset0), address(this), 1e22);
    asset0.approve(address(pool), 1e22);

    uint256 asset0StartBalance = asset0.balanceOf(address(this));
    uint256 asset1StartBalance = asset1.balanceOf(address(this));

    pool.swapInFixed(address(asset0), 1e21);

    uint256 asset0Delta = asset0StartBalance - asset0.balanceOf(address(this));
    uint256 asset1Delta = asset1.balanceOf(address(this)) - asset1StartBalance;

      // XXX: Expectations here are wrong, they don't take fee into account
    assertEq(asset0Delta, 1e21);
    assertEq(asset1Delta, 1e21);
  }

  function test_swapFixedAmountOutWithFee() public {
    deposit();

    deal(address(asset0), address(this), 1e22);
    asset0.approve(address(pool), 1e22);

    uint256 asset0StartBalance = asset0.balanceOf(address(this));
    uint256 asset1StartBalance = asset1.balanceOf(address(this));

    pool.swapOutFixed(address(asset0), 1e21);

    uint256 asset0Delta = asset0StartBalance - asset0.balanceOf(address(this));
    uint256 asset1Delta = asset1.balanceOf(address(this)) - asset1StartBalance;

      // XXX: Expectations here are wrong, they don't take fee into account
    assertEq(asset0Delta, 1e21);
    assertEq(asset1Delta, 1e21);
  }
}
