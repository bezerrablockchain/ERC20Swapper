// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script, console} from "forge-std/Script.sol";

import {ERC20Swapper} from "../src/ERC20Swapper.sol";

contract ERC20SwapperScript is Script {
    address public implementation;
    address public proxyAddress;
    bytes public implemetationData;

    function run() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        console.log("deployer", deployer);

        vm.startBroadcast(privateKey);

        ERC20Swapper erc20Swapper = new ERC20Swapper();
        console.log(
            "ERC20Swapper implementation deployed at: ",
            address(erc20Swapper)
        );
        implementation = address(erc20Swapper);
        implemetationData = bytes.concat(erc20Swapper.initialize.selector);

        proxyAddress = address(
            new ERC1967Proxy(implementation, implemetationData)
        );
        console.log("ERC20Swapper proxy deployed at: ", proxyAddress);

        vm.stopBroadcast();
    }
}
