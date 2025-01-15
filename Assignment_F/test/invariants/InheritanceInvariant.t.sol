// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Inheritance} from "../../src/Inheritance.sol";
import {Handler} from "./handler.t.sol";

contract InheritanceInvariant is StdInvariant, Test {
    Inheritance public inheritance;
    Handler public handler;
    // Addresses
    address public owner = makeAddr("onwer");
    address public heir = makeAddr("heir");
    address public newHeir = makeAddr("newHeir");
    address public other = makeAddr("other");

    uint256 public lastWithdrawlTime;

    event EthDeposited(address indexed from, uint256 amount);

    event WithdrawalCompletedAndTimeUpdated(address indexed to, uint256 amount, uint256 newLastWithdrawalTime);

    event InheritanceStateUpdated(
        address indexed oldOwner, address indexed newOwner, address indexed newHeir, uint256 newLastWithdrawalTime
    );

    function setUp() public {
        vm.prank(owner);
        inheritance = new Inheritance(heir);
        handler = new Handler(inheritance);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.withdraw.selector;
        selectors[2] = handler.claimOwnership.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    function statefulFuzz_Non_Zero_Owner() public view {
        assert(inheritance.owner() != address(0));
    }

    function statefulFuzz_Non_Zero_Heir() public view {
        assert(inheritance.heir() != address(0));
    }

    function statefulFuzz_Owner_is_Heir() public view {
        assert(inheritance.owner() != inheritance.heir());
    }

    function statefulFuzz_lastWithdrawal_time_is_non_zero() public view {
        assert(inheritance.lastWithdrawalTime() != 0);
    }

    function statefulFuzz_lastWithdrawal_time_is_not_in_Future() public view {
        assert(inheritance.lastWithdrawalTime() <= block.timestamp);
    }
}
