// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IERC20Swapper.sol";

contract ERC20Swapper is IERC20Swapper, UUPSUpgradeable, OwnableUpgradeable {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
    }

    /// @dev swaps the `msg.value` Ether to at least `minAmount` of tokens in `address`, or reverts
    /// @param token The address of ERC-20 token to swap
    /// @param minAmount The minimum amount of tokens transferred to msg.sender
    /// @return amountOut The actual amount of transferred tokens
    function swapEtherToToken(
        address token,
        uint minAmount
    ) external payable returns (uint amountOut) {
        address swapRouter = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
        address WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
        uint24 poolFee = 3000;

        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: token,
            fee: poolFee,
            recipient: msg.sender,
            amountIn: msg.value,
            amountOutMinimum: minAmount,
            sqrtPriceLimitX96: 0
        });

        bytes memory message = abi.encodeWithSignature(
            "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
            params
        );
        (bool sent, bytes memory data) = address(swapRouter).call{
            value: msg.value
        }(message);

        require(sent, "Failed to swap Ether to Token");

        amountOut = uint256(bytes32(data));

        require(amountOut >= minAmount, "Min value not reached.");

        return amountOut;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
}
