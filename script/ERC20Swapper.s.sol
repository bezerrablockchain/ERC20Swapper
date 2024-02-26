// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Swapper} from "../src/ERC20Swapper.sol";

contract ERC20SwapperScript is Script {
    function run() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        console.log("deployer", deployer);

        vm.startBroadcast(privateKey);
        ERC20Swapper erc20Swapper = new ERC20Swapper();
        vm.stopBroadcast();

        console.log("ERC20Swapper deployed at: ", address(erc20Swapper));
    }
}
