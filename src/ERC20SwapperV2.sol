// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./IERC20Swapper.sol";

contract ERC20SwapperV2 is
    IERC20Swapper,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    event TokenSwapped(
        address indexed tokenAddress,
        uint256 indexed amountIn,
        uint256 indexed amountOut,
        uint minAmount
    );

    error MinValueNotReached();
    error NonZeroValueAllowed();

    //These addresses bellow are from Polygon Mainnet
    address constant SWAP_ROUTER_ADDR =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant WETH9 = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    uint24 constant POOL_FEE = 3000;
    string public constant version = "v2";

    constructor() {
        // __disableInitializers();
    }
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    // @dev swaps the `msg.value` Ether to at least `minAmount` of tokens in `address`, or reverts
    // @param token The address of ERC-20 token to swap
    // @param minAmount The minimum amount of tokens transferred to msg.sender
    // @return amountOut The actual amount of transferred tokens
    function swapEtherToToken(
        address token,
        uint minAmount
    ) external payable nonReentrant returns (uint amountOut) {
        if (msg.value == 0) {
            revert NonZeroValueAllowed();
        }

        ISwapRouter swapRouter = ISwapRouter(SWAP_ROUTER_ADDR);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WMATIC,
                tokenOut: token,
                fee: POOL_FEE,
                recipient: msg.sender,
                deadline: block.timestamp + 1500,
                amountIn: msg.value,
                amountOutMinimum: minAmount,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle{value: msg.value}(params);
        if (amountOut < minAmount) revert MinValueNotReached();

        emit TokenSwapped(token, msg.value, amountOut, minAmount);
        return amountOut;
    }

    // @dev _authorizeUpgrade is used by the OpenZeppelin's UUPSUpgradeable to authorize the upgrade
    // @dev This function can only be called by the owner
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
