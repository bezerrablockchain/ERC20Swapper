// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Script, console} from "forge-std/Script.sol";
import {ERC20Swapper} from "../src/ERC20Swapper.sol";

contract ERC20SwapperDeployer is Script {
    ERC20Swapper implSwapper;
    ERC1967Proxy proxy;
    uint256 privateKey;
    address deployer;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.addr(privateKey);
        console.log("deployer", deployer);
    }

    function run() public {
        vm.startBroadcast(privateKey);

        implSwapper = new ERC20Swapper();
        proxy = new ERC1967Proxy(address(implSwapper), "");
        ERC20Swapper swapper = ERC20Swapper(address(proxy));
        swapper.initialize();

        vm.stopBroadcast();

        console.log("Implementation contract ERC20Swapper deployed at: ", address(implSwapper));
        console.log("Proxy contract ERC20Swapper deployed at: ", address(proxy));
    }
}
