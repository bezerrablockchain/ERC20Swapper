// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20Swapper.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ERC20SwapperTest is Test {
    ERC20Swapper swapper;
    ERC1967Proxy proxy;
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
        ERC20Swapper implERC20Swapper = new ERC20Swapper();
        proxy = new ERC1967Proxy(address(implERC20Swapper), "");
        swapper = ERC20Swapper(address(proxy));
        swapper.initialize();
        vm.stopPrank();
    }

    function testSwapEtherToToken() public {
        uint256 minAmount = 500000; //minAmount in USDC means 0,50 USDC for 1 Matic is the minimum amountOut

        (bool success, ) = address(swapper).call{
            value: 1 ether
        }(
            abi.encodeWithSignature(
                "swapEtherToToken(address,uint256)",
                tokenOut,
                minAmount
            )
        );
        assertTrue(success, "Swap failed");
    }

    function testSwapEtherToTokenFailMinValueNotReached() public {
        uint256 minAmount = 5000000; //minAmount in USDC means 5 USDC for 1 Matic is the minimum amountOut
        
        (bool success, ) = address(swapper).call{
            value: 1 ether
        }(
            abi.encodeWithSignature(
                "swapEtherToToken(address,uint256)",
                tokenOut,
                minAmount
            )
        );
        assertFalse(success, "Swap failed");
    }
    function testSwapEtherToTokenFailNonZeroValueAllowed() public {
        uint256 minAmount = 500000; //minAmount in USDC means 0,50 USDC for 1 Matic is the minimum amountOut

        (bool success, ) = address(swapper).call{
            value: 0
        }(
            abi.encodeWithSignature(
                "swapEtherToToken(address,uint256)",
                tokenOut,
                minAmount
            )
        );
        assertFalse(success, "Swap failed");
    }
    function testSwapEtherToTokenFailSwapFailed() public {
        uint256 minAmount = 500000; //minAmount in USDC means 0,50 USDC for 1 Matic is the minimum amountOut

        vm.expectRevert("Swap failed");
        (bool success, ) = address(swapper).call{
            value: 1 ether
        }(
            abi.encodeWithSignature(
                "swapEtherToToken(address,uint256)",
                address(0x007777888999), //Non-existent token
                minAmount
            )
        );
        assertFalse(success, "Swap failed");
    }

    function testUpgrade() public {
        vm.startPrank(owner);
        ERC20Swapper newImpl = new ERC20Swapper(); //Using same code, but it could be a v2

        swapper.upgradeToAndCall(address(newImpl), "");

        swapper = ERC20Swapper(address(proxy));
        vm.stopPrank();
    }
}
