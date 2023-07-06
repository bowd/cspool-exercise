// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20Metadata } from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import { PRBMathUD60x18Typed, PRBMath } from "prb-math/PRBMathUD60x18Typed.sol";

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

  PRBMath.UD60x18 fee;

  constructor(
    address _asset0,
    address _asset1,
    uint256 _fee
  ) {
    asset0 = _asset0;
    asset1 = _asset1;

    fee = PRBMath.UD60x18({value: _fee});
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
    address assetOut;
    if (assetIn == asset0) {
      bucket0 += amountIn;
      bucket1 -= amountOut;
      assetOut = asset1;
    } else {
      bucket1 += amountIn;
      bucket0 -= amountOut;
      assetOut = asset0;
    }

    IERC20Metadata(assetIn).transferFrom(msg.sender, address(this), amountIn);
    IERC20Metadata(assetOut).transfer(msg.sender, amountOut);
  }

  function swapIn(address assetIn, uint256 amountOut) external returns (uint256 amountIn) {
    amountIn = _getAmountIn(assetIn, amountOut);
    address assetOut;
    if (assetIn == asset0) {
      bucket0 += amountIn;
      bucket1 -= amountOut;
      assetOut = asset1;
    } else {
      bucket1 += amountIn;
      bucket0 -= amountOut;
      assetOut = asset0;
    }

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
    amountOut = _amountIn;
    // Todo add fee calculation

    require(amountOut <= bucketOut, "insufficient liquidity");
  }

  function _getAmountIn(address assetIn, uint256 _amountOut) internal view returns (uint256 amountIn) {
    uint256 bucketOut;
    if (assetIn == asset0) {
      bucketOut = bucket1;
    } else {
      bucketOut = bucket0;
    }

    // x + y = k
    amountIn = _amountOut;
    // Todo add fee calculation

    require(_amountOut <= bucketOut, "insufficient liquidity");
  }
}
