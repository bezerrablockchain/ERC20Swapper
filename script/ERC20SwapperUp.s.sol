// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Script, console} from "forge-std/Script.sol";
import {ERC20Swapper} from "../src/ERC20Swapper.sol";
import {ERC20SwapperV2} from "../src/ERC20SwapperV2.sol";

contract ERC20SwapperDeployer is Script {
    ERC20Swapper swapperV1;
    ERC20SwapperV2 swapperV2;
    ERC1967Proxy proxy;
    uint256 privateKey;
    address deployer;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(privateKey);

        proxy = ERC1967Proxy(payable(vm.envAddress("ERC20SWAPPER_PROXY")));
        swapperV1 = ERC20Swapper(address(proxy));

        console.log("deployer", deployer);
    }

    function run() public {
        vm.startBroadcast(privateKey);

        ERC20SwapperV2 impSwapperV2 = new ERC20SwapperV2();
        swapperV1.upgradeToAndCall(address(impSwapperV2), "");

        swapperV2 = ERC20SwapperV2(address(proxy));

        console.log("Implementation contract ERC20Swapper deployed at: ", address(swapperV2));
        console.log("Proxy contract ERC20Swapper deployed at: ", address(proxy));
        console.log("Actual Version is: ", swapperV2.version());

        vm.stopBroadcast();
    }
}
