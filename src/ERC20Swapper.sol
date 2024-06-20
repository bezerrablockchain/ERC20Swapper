// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./IERC20Swapper.sol";

contract ERC20Swapper is
    IERC20Swapper,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    event TokenSwapped(
        address indexed tokenAddress,
        uint256 indexed amountIn,
        uint256 indexed amountOut,
        uint minAmount
    );

    error FailedToSwap();
    error MinValueNotReached();
    error NonZeroValueAllowed();

    address constant SWAP_ROUTER_ADDR =
        0xE592427A0AEce92De3Edee1F18E0157C05861564; //Polygon
    address constant WETH9 = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; //Polygon
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; //Polygon
    uint24 constant POOL_FEE = 3000;

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    function swapEtherToToken(
        address token,
        uint minAmount
    ) external payable returns (uint amountOut) {
        if (msg.value == 0) {
            revert NonZeroValueAllowed();
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                // tokenIn: swapRouter.WETH9(),
                tokenIn: WMATIC,
                tokenOut: token,
                fee: POOL_FEE,
                recipient: msg.sender,
                deadline: block.timestamp + 1500,
                amountIn: msg.value,
                amountOutMinimum: minAmount,
                sqrtPriceLimitX96: 0
            });

        uint amountOut = swapRouter.exactInputSingle{value: msg.value}(params);
        if (amountOut < minAmount) revert MinValueNotReached();

        emit TokenSwapped(token, msg.value, amountOut, minAmount);
        return amountOut;
    }

    // // @dev swaps the `msg.value` Ether to at least `minAmount` of tokens in `address`, or reverts
    // // @param token The address of ERC-20 token to swap
    // // @param minAmount The minimum amount of tokens transferred to msg.sender
    // // @return amountOut The actual amount of transferred tokens
    // function swapEtherToToken2(
    //     address token,
    //     uint minAmount
    // ) external payable returns (uint amountOut) {

    //     ExactInputSingleParams memory params = ExactInputSingleParams({
    //         tokenIn: WETH9,
    //         tokenOut: token,
    //         fee: POOL_FEE,
    //         recipient: msg.sender,
    //         amountIn: msg.value,
    //         amountOutMinimum: minAmount,
    //         sqrtPriceLimitX96: 0
    //     });

    //     bytes memory message = abi.encodeWithSignature(
    //         "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))",
    //         params
    //     );
    //     (bool sent, bytes memory data) = address(SWAP_ROUTER_ADDR).call{
    //         value: msg.value
    //     }(message);

    //     if(!sent) revert FailedToSwap();

    //     amountOut = uint256(bytes32(data));

    //     if(amountOut < minAmount) revert MinValueNotReached();

    //     return amountOut;
    // }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
