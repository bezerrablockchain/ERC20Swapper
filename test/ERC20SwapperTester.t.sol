// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20Swapper.sol";

contract ERC20SwapperTest is Test {
    ERC20Swapper swapper;
    address swapperProxy = 0xeA853Fa1181c28DCDE62e067923287771723a9A0; // Deployed contract address
    address tokenOut = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // Token to swap to

    function setUp() public {
        swapper = ERC20Swapper(swapperProxy);
    }

    function testSwapEtherToToken() public {
        uint256 minAmount = 0 ether;

        // This test assumes you're already connected to Sepolia and can send transactions
        // Sending Ether to the swapper contract to simulate swap
        (bool success, bytes memory retMsg) = address(swapper).call{value: 0.01 ether}(abi.encodeWithSignature("swapEtherToToken(address,uint256)", tokenOut, minAmount));
        console.logBytes(retMsg);
        console.logUint(uint256(bytes32(retMsg)));
        assertTrue(success, "Swap failed");
    }
}
