// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./UniswapPolygon.sol";
import "./IERC20Swapper.sol";

contract ERC20Swapper is
    IERC20Swapper,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UniswapPolygon
{
    // @dev emitted when a token is swapped
    event TokenSwapped(
        address indexed tokenAddress,
        uint256 indexed amountIn,
        uint256 indexed amountOut,
        uint minAmount
    );

    // @dev emitted when the minimum value is not reached
    error MinValueNotReached();
    // @dev emitted when the value is zero
    error NonZeroValueAllowed();
    // @dev emitted when the pool is not found
    error PoolNotFound();

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
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

        // @dev get the pool fee of the token
        // @dev also validate if a pool exists for the token (fee != 0)
        uint24 poolFee = getUniswapPoolFee(token);
        if (poolFee == 0) {
            revert PoolNotFound();
        }

        amountOut = uniswapSwap(token, poolFee, minAmount);
        if (amountOut < minAmount) revert MinValueNotReached();

        emit TokenSwapped(token, msg.value, amountOut, minAmount);
        return amountOut;
    }

    // @notice this function serves to track the actual implementation version
    // @dev change it to a new version when you code a new version
    function getVersion() external pure returns (string memory) {
        return "V1.0";
    }

    // @dev _authorizeUpgrade is used by the OpenZeppelin's UUPSUpgradeable to authorize the upgrade
    // @dev This function can only be called by the owner
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
