// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
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
    event TokenSwapped(
        address indexed tokenAddress,
        uint256 indexed amountIn,
        uint256 indexed amountOut,
        uint minAmount
    );

    error MinValueNotReached();
    error NonZeroValueAllowed();
    error PoolNotFound();

    //These addresses bellow are from Polygon Mainnet
    address constant FACTORY_ADDR = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant SWAP_ROUTER_ADDR =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    IUniswapV3Factory public factory;
    ISwapRouter public swapRouter;

    constructor() {
        // __disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        factory = IUniswapV3Factory(FACTORY_ADDR);
        swapRouter = ISwapRouter(SWAP_ROUTER_ADDR);
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

        uint24 poolFee = _getPoolFee(token);
        if (poolFee == 0) {
            revert PoolNotFound();
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WMATIC,
                tokenOut: token,
                fee: poolFee,
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

    // @notice This function uses the most common pool fee of uniswaps pools
    // @dev _getPoolFee returns the pool fee of the token
    // @param token The address of ERC-20 token
    // @return poolFee The pool fee of the token
    function _getPoolFee(address token) internal view returns (uint24) {
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

    // @dev _authorizeUpgrade is used by the OpenZeppelin's UUPSUpgradeable to authorize the upgrade
    // @dev This function can only be called by the owner
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
