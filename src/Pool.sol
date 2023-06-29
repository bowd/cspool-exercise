// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20Metadata } from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

contract ConstantSumPool {
  address public asset0;
  uint256 public asset0DecimalMultiplier;
  uint256 public bucket0;

  address public asset1;
  uint256 public bucket1;
  uint256 public asset1DecimalMultiplier;

  constructor(
    address _asset0,
    address _asset1
  ) {
    asset0 = _asset0;
    uint8 asset0Decimals = IERC20Metadata(_asset0).decimals());
    require(asset0Decimals <= 18, "asset0 decimals must be <= 18");
    asset0DecimalMultiplier = 1 ** (18 - asset0Decimals);

    asset1 = _asset1;
    uint8 asset1Decimals = IERC20Metadata(_asset1).decimals());
    require(asset0Decimals <= 18, "asset1 decimals must be <= 18");
    asset1DecimalMultiplier = 1 ** (18 - asset1Decimals);
  }

  function depost(uint256 amount0, uint256 amount1) public {
    require (
      amount0 * asset0DecimalMultiplier == amount1 * asset1DecimalMultiplier,
      "amount0 and amount1 must be the same"
    );
    IERC20Metadata(asset0).transferFrom(msg.sender, address(this), amount0);
    IERC20Metadata(asset1).transferFrom(msg.sender, address(this), amount1);

    bucket0 += asset0 * asset0DecimalMultiplier;
    bucket1 += asset1 * asset1DecimalMultiplier;
  }

  function getAmountOut(address assetIn, uint256 amountIn) {
    if (assetIn == asset0) {
      return amountIn * bucket1 / bucket0;
    } else if (assetIn == asset1) {
      return amountIn * bucket0 / bucket1;
    } else {
      revert("assetIn must be asset0 or asset1");
    }
  }
}
