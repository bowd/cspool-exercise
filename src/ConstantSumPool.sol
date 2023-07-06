// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20Metadata } from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import { PRBMathUD60x18Typed, PRBMath } from "prb-math/PRBMathUD60x18Typed.sol";

/**
 * @title ConstantSumPool
 * @dev A constant sum pool that allows swapping between two assets with the same price.
 */
contract ConstantSumPool {
  using PRBMathUD60x18Typed for PRBMath.UD60x18;

  address public asset0;
  uint256 public asset0DecimalMultiplier;
  uint256 public bucket0;

  address public asset1;
  uint256 public bucket1;
  uint256 public asset1DecimalMultiplier;

  PRBMath.UD60x18 fee;

  constructor(
    address _asset0,
    address _asset1,
    uint256 _fee
  ) {
    asset0 = _asset0;
    uint8 asset0Decimals = IERC20Metadata(_asset0).decimals();
    require(asset0Decimals <= 18, "asset0 decimals must be <= 18");
    asset0DecimalMultiplier = 1 ** (18 - asset0Decimals);

    asset1 = _asset1;
    uint8 asset1Decimals = IERC20Metadata(_asset1).decimals();
    require(asset0Decimals <= 18, "asset1 decimals must be <= 18");
    asset1DecimalMultiplier = 1 ** (18 - asset1Decimals);

    fee = PRBMath.UD60x18({value: _fee});
  }

  function deposit(uint256 amount0, uint256 amount1) public {
    require (
      amount0 * asset0DecimalMultiplier == amount1 * asset1DecimalMultiplier,
      "amount0 and amount1 must be the same"
    );
    IERC20Metadata(asset0).transferFrom(msg.sender, address(this), amount0);
    IERC20Metadata(asset1).transferFrom(msg.sender, address(this), amount1);

    bucket0 += amount0 * asset0DecimalMultiplier;
    bucket1 += amount1 * asset1DecimalMultiplier;
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

  function _getAmountOut(address assetIn, uint256 _amountIn) private view returns (uint256) {
    uint256 assetInDecimalMultiplier;
    uint256 assetOutDecimalMultiplier;
    uint256 bucketOut;
    if (assetIn == asset0) {
      assetInDecimalMultiplier = asset0DecimalMultiplier;
      assetOutDecimalMultiplier = asset1DecimalMultiplier;
      bucketOut = bucket1;
    } else {
      assetInDecimalMultiplier = asset1DecimalMultiplier;
      assetOutDecimalMultiplier = asset0DecimalMultiplier;
      bucketOut = bucket0;
    }

    PRBMath.UD60x18 memory amountIn = PRBMath.UD60x18({value: _amountIn * assetInDecimalMultiplier});
    PRBMath.UD60x18 memory constant_1 = PRBMath.UD60x18({value: 1e18});
    PRBMath.UD60x18 memory amountOut = amountIn.mul(constant_1.sub(fee));

    require(amountOut.value <= bucketOut, "insufficient liquidity");
    return amountOut.value / assetOutDecimalMultiplier;
  }

  function _getAmountIn(address assetIn, uint256 _amountOut) private view returns (uint256) {
    uint256 assetInDecimalMultiplier;
    uint256 assetOutDecimalMultiplier;
    uint256 bucketOut;
    if (assetIn == asset0) {
      assetInDecimalMultiplier = asset0DecimalMultiplier;
      assetOutDecimalMultiplier = asset1DecimalMultiplier;
      bucketOut = bucket1;
    } else {
      assetInDecimalMultiplier = asset1DecimalMultiplier;
      assetOutDecimalMultiplier = asset0DecimalMultiplier;
      bucketOut = bucket0;
    }

    PRBMath.UD60x18 memory amountOut = PRBMath.UD60x18({value: _amountOut * assetOutDecimalMultiplier});
    PRBMath.UD60x18 memory constant_1 = PRBMath.UD60x18({value: 1e18});
    PRBMath.UD60x18 memory amountIn = amountOut.div(constant_1.sub(fee));

    require(amountOut.value <= bucketOut, "insufficient liquidity");
    return amountIn.value / assetInDecimalMultiplier;
  }
}
