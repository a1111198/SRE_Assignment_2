// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Inheritance} from "../../src/Inheritance.sol";

contract Handler is Test {
    Inheritance inheritance;

    constructor(Inheritance _inheritance) {
        inheritance = _inheritance;
    }

    function deposit(uint256 _amount) public {
        uint256 amount = bound(_amount, 0, 100 ether);
        vm.deal(msg.sender, amount);
        vm.prank(msg.sender);
        inheritance.deposit{value: amount}();
    }

    function withdraw(uint256 _amount) external {
        uint256 amount = bound(_amount, 0, address(inheritance).balance);
        address _owner = inheritance.owner();
        vm.assume(uint160(_owner) > 9 && _owner.code.length == 0);
        address consoleAddr = 0x000000000000000000636F6e736F6c652e6c6f67; // console Address
        vm.assume(consoleAddr != _owner);
        vm.prank(_owner);
        inheritance.withdraw(amount);
    }

    function claimOwnership(address _newHeir, uint256 _iactivityTimeInSeconds) external {
        vm.assume(_newHeir != address(0));
        vm.assume(_newHeir != inheritance.heir());
        uint256 inactivityTimeInSeconds = bound(_iactivityTimeInSeconds, 30 days + 1, type(uint32).max);
        vm.warp(block.timestamp + inactivityTimeInSeconds);
        address _lastHeir = inheritance.heir();
        vm.prank(_lastHeir);
        inheritance.claimOwnership(_newHeir);
        // only Heir can be new Owner
        assert(inheritance.owner() == _lastHeir);
    }
}
