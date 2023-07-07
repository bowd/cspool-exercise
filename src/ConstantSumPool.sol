// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { PRBMathUD60x18Typed, PRBMath } from "@prb/math/contracts/PRBMathUD60x18Typed.sol";

/**
 * @title Pool
 * @dev A constant sum pool that allows swapping between two assets with the same price.
 */
contract ConstantSumPool {
  using PRBMathUD60x18Typed for PRBMath.UD60x18;

  address public asset0;
  uint256 public bucket0;

  address public asset1;
  uint256 public bucket1;

  PRBMath.UD60x18 public swapFee;

  constructor(
    address _asset0,
    address _asset1,
    uint256 _swapFee
  ) {
    asset0 = _asset0;
    asset1 = _asset1;

    swapFee = PRBMath.UD60x18({value: _swapFee});
  }

  function deposit(uint256 amount0, uint256 amount1) public {
    IERC20Metadata(asset0).transferFrom(msg.sender, address(this), amount0);
    IERC20Metadata(asset1).transferFrom(msg.sender, address(this), amount1);

    bucket0 += amount0;
    bucket1 += amount1;
  }

  function getAmountOut(address assetIn, uint256 _amountIn) external view returns (uint256) {
    return _getAmountOut(assetIn, _amountIn);
  }

  function getAmountIn(address assetIn, uint256 _amountOut) external view returns (uint256) {
    return _getAmountIn(assetIn, _amountOut);
  }

  function swapOut(address assetIn, uint256 amountIn) external returns (uint256 amountOut) {
    amountOut = _getAmountOut(assetIn, amountIn);
    address assetOut = assetIn == asset0 ? asset1 : asset0;
    _updateBuckets(assetIn, amountIn, amountOut);

    IERC20Metadata(assetIn).transferFrom(msg.sender, address(this), amountIn);
    IERC20Metadata(assetOut).transfer(msg.sender, amountOut);
  }

  function swapIn(address assetIn, uint256 amountOut) external returns (uint256 amountIn) {
    amountIn = _getAmountIn(assetIn, amountOut);
    address assetOut = assetIn == asset0 ? asset1 : asset0;
    _updateBuckets(assetIn, amountIn, amountOut);

    IERC20Metadata(assetIn).transferFrom(msg.sender, address(this), amountIn);
    IERC20Metadata(assetOut).transfer(msg.sender, amountOut);
  }

  function _getAmountOut(address assetIn, uint256 _amountIn) internal view returns (uint256 amountOut) {
    uint256 bucketOut;
    if (assetIn == asset0) {
      bucketOut = bucket1;
    } else {
      bucketOut = bucket0;
    }
    // x + y = k
    // x + Δx + y - Δy = k
    // Δx - Δy = 0
    // Δx = Δy
    // Todo add fee calculation
    amountOut = _amountIn;
  }

  function _getAmountIn(address assetIn, uint256 _amountOut) internal view returns (uint256 amountIn) {
    uint256 bucketOut;
    if (assetIn == asset0) {
      bucketOut = bucket1;
    } else {
      bucketOut = bucket0;
    }

    // x + y = k
    // x + Δx + y - Δy = k
    // Δx - Δy = 0
    // Δx = Δy
    // Todo add fee calculation

    amountIn = _amountOut;
  }

  function _updateBuckets(address assetIn, uint256 amountIn, uint256 amountOut) internal {
    if (assetIn == asset0) {
      require(amountOut < bucket1, "insufficient liquidity");
      bucket0 += amountIn;
      bucket1 -= amountOut;
    } else {
      require(amountOut < bucket0, "insufficient liquidity");
      bucket0 -= amountOut;
      bucket1 += amountIn;
    }
  }
}
