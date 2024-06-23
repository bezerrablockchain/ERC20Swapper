// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

abstract contract UniswapPolygon {
    address constant FACTORY_ADDR = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant ROUTER_ADDR =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    // @notice This function uses the most common pool fee of uniswaps pools
    // @dev _getPoolFee returns the pool fee of the token
    // @param token The address of ERC-20 token
    // @return poolFee The pool fee of the token
    function getUniswapPoolFee(address token) public view returns (uint24) {
        IUniswapV3Factory factory = IUniswapV3Factory(FACTORY_ADDR);
        uint24[] memory commonPoolFeeSet = new uint24[](4);
        unchecked {
            commonPoolFeeSet[0] = 100;
            commonPoolFeeSet[1] = 500;
            commonPoolFeeSet[2] = 3000;
            commonPoolFeeSet[3] = 10000;
        }
        unchecked {
            for (uint i; i < commonPoolFeeSet.length; ++i) {
                if (
                    factory.getPool(token, WMATIC, commonPoolFeeSet[i]) !=
                    address(0)
                ) {
                    return commonPoolFeeSet[i];
                }
            }
        }
        return 0;
    }

    // @notice This function swaps MATIC for ERC-20 token
    // @dev uniswapSwap swaps MATIC for ERC-20 token
    // @param token The address of ERC-20 token
    // @param fee The pool fee of the token
    // @param minAmount The minimum amount of token to receive
    // @return amountOut The amount of token received
    function uniswapSwap(
        address token,
        uint24 fee,
        uint minAmount
    ) public payable returns (uint amountOut) {
        ISwapRouter router = ISwapRouter(ROUTER_ADDR);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WMATIC,
                tokenOut: token,
                fee: fee,
                recipient: msg.sender,
                deadline: block.timestamp + 1500,
                amountIn: msg.value,
                amountOutMinimum: minAmount,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle{value: msg.value}(params);
    }
}
