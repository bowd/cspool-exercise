import "./tERC20.sol";

contract USDC is tERC20 {
  constructor(string memory name, string memory symbol) tERC20(name, symbol) {}

  function decimals() override public pure returns (uint8) {
    return 6;
  }
}

