// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20Swapper.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ERC20SwapperTest is Test {
    ERC20Swapper swapper;
    address owner = address(0x777888999);
    address user01 = address(0x123456789);
    address tokenOut = address(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359); //USDC

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(forkId);

        vm.deal(owner, 10 ether);
        vm.deal(user01, 10 ether);

        vm.startPrank(owner);
        // Deploy instance and get a proxy address
        implERC20Swapper = new ERC20Swapper();
        proxy = new ERC1967Proxy(address(implERC20Swapper), "");
        swapper = ERC20Swapper(address(proxy));
        swapper.initialize();
        vm.stopPrank();
    }

    function testSwapEtherToToken() public {
        uint256 minAmount = 1;

        // This test assumes you're already connected to Sepolia and can send transactions
        // Sending Ether to the swapper contract to simulate swap
        (bool success, bytes memory retMsg) = address(swapper).call{value: 0.01 ether}(abi.encodeWithSignature("swapEtherToToken(address,uint256)", tokenOut, minAmount));
        console.logBytes(retMsg);
        console.logUint(uint256(bytes32(retMsg)));
        assertTrue(success, "Swap failed");
    }
}
