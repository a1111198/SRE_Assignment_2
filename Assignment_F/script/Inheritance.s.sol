// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Inheritance} from "../src/Inheritance.sol";

contract InheritanceScript is Script {
    address public heir = 0xF17FC7200FA3265fF5E1D9C5d1d2f08cDaFAe8D9;

    function run() public returns (Inheritance inheritance) {
        vm.startBroadcast();
        inheritance = new Inheritance(heir);
        vm.stopBroadcast();
    }
}
