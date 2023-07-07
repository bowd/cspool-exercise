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

  function testDeposit() public {
    deal(address(asset0), address(this), 10e22);
    deal(address(asset1), address(this), 10e22);

    asset0.approve(address(pool), 10e22);
    asset1.approve(address(pool), 10e22);
    pool.deposit(10e22, 10e22);
  }

  function testSwapWithFee() public {
    deal(address(asset0), address(this), 1e24);
    deal(address(asset1), address(this), 1e24);

    asset0.approve(address(pool), 1e24);
    asset1.approve(address(pool), 1e24);

    pool.deposit(10e22, 10e22);
    uint256 expectedOut0 = pool.swapOut(address(asset0), 1e21);
    uint256 expectedOut1 = pool.swapOut(address(asset0), 1e21);

    assertEq(expectedOut0, 999e18);
    assertEq(expectedOut1, 999e18);
    assertEq(pool.bucket0(), 102e21);
    assertEq(pool.bucket1(), 98e21 + 2e18); // with fee
  }
}
