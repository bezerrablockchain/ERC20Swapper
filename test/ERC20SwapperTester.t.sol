// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC20Swapper.sol";
import "../src/ERC20SwapperV2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20SwapperTest is Test {
    ERC1967Proxy proxy;
    ERC20Swapper swapper;
    address owner;

    address user01 = address(0x123456789);
    address tokenOut = address(0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359); //USDC
    uint256 constant MIN_AMOUNT = 500000; //minAmount in USDC means 0,50 USDC for 1 Matic is the minimum amountOut

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("MAINNET_RPC_URL"));
        vm.selectFork(forkId);

        owner = vm.envAddress("OWNER");
        proxy = ERC1967Proxy(payable(vm.envAddress("ERC20SWAPPER_PROXY")));
        swapper = ERC20Swapper(address(proxy));

        vm.deal(owner, 10 ether);
        vm.deal(user01, 10 ether);
    }

    function testSwapEtherToToken() public {
        uint256 initialBalance = IERC20(tokenOut).balanceOf(user01);
        
        vm.prank(user01);
        (bool success, bytes memory retMsg) = address(swapper).call{
            value: 1 ether
        }(
            abi.encodeWithSignature(
                "swapEtherToToken(address,uint256)",
                tokenOut,
                MIN_AMOUNT
            )
        );
        assertTrue(success, "Swap failed");

        uint256 amountTransferred = abi.decode(retMsg, (uint256));
        uint256 balance = IERC20(tokenOut).balanceOf(user01);

        assertEq(balance, initialBalance + amountTransferred);
    }

    function testSwapEtherToTokenFailMinValueNotReached() public {
        uint256 overMinAmount = MIN_AMOUNT * 10;

        vm.expectRevert("Too little received"); // This revert comes from Uniswap
        vm.prank(user01);
        swapper.swapEtherToToken{value: 1 ether}(tokenOut, overMinAmount);
    }

    function testSwapEtherToTokenFailNonZeroValueAllowed() public {
        vm.expectRevert(
            abi.encodeWithSelector(ERC20Swapper.NonZeroValueAllowed.selector)
        );
        vm.prank(user01);
        swapper.swapEtherToToken(tokenOut, MIN_AMOUNT);
    }

    function testSwapEtherToTokenFailSwapFailed() public {
        vm.expectRevert(
            abi.encodeWithSelector(ERC20Swapper.PoolNotFound.selector)
        );
        vm.prank(user01);
        swapper.swapEtherToToken{value: 1 ether}(
            address(0x007777888999),
            MIN_AMOUNT
        );
    }

    function testUpgrade() public {
        vm.startPrank(owner);
        assertEq(swapper.getVersion(), "V1.0");
        ERC20SwapperV2 newImpl = new ERC20SwapperV2();

        swapper.upgradeToAndCall(address(newImpl), "");

        ERC20SwapperV2 swapperv2 = ERC20SwapperV2(address(proxy));
        assertEq(swapperv2.getVersion(), "V2.0");

        vm.stopPrank();
    }
}
