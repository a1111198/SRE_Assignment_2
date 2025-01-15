// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Inheritance} from "../../src/Inheritance.sol";
import {InheritanceScript} from "../../script/Inheritance.s.sol";

contract InheritanceTest is Test {
    Inheritance public inheritance;
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
        lastWithdrawlTime = block.timestamp;
        inheritance = new Inheritance(heir);
    }

    function test_Deploy_Script() public {
        InheritanceScript inheritanceScript = new InheritanceScript();
        inheritance = inheritanceScript.run();
        assertEq(inheritance.heir(), inheritanceScript.heir());
    }

    function test_constructor_Zero_heir() public {
        vm.expectRevert(Inheritance.MustBeNonZeroAddress.selector);
        inheritance = new Inheritance(address(0));
    }

    function test_constructor_owner_as_heir() public {
        vm.expectRevert(Inheritance.OwnerAndHeirMustBeDifferent.selector);
        vm.prank(owner);
        inheritance = new Inheritance(owner);
    }

    function test_constructor_Deposit_Event() public {
        vm.deal(owner, 1 ether);
        vm.prank(owner);
        vm.expectEmit(true, true,true,true);
        emit EthDeposited(owner, 1 ether);
        inheritance = new Inheritance{value: 1 ether}(heir);
    }

    function test_constructor() public view {
        assertEq(inheritance.owner(), owner);
        assertEq(inheritance.heir(), heir);
        assertEq(inheritance.lastWithdrawalTime(), lastWithdrawlTime);
    }

    modifier depositinInheritance() {
        vm.deal(other, 1 ether);
        vm.prank(other);
        inheritance.deposit{value: 1 ether}();
        _;
    }

    function test_deposit() public depositinInheritance {
        assertEq(address(inheritance).balance, 1 ether);
    }

    function test_receiveEvent() public {
        vm.deal(other, 1 ether);
        vm.prank(other);
        vm.expectEmit(true, true, true, true, address(inheritance));
        emit EthDeposited(other, 1 ether);
        (bool success,) = address(inheritance).call{value: 1 ether}("");
        assert(success);
    }

    function test_receiveEvent_withDeposit() public {
        vm.deal(other, 1 ether);
        vm.prank(other);
        vm.expectEmit(true, true, true, true, address(inheritance));
        emit EthDeposited(other, 1 ether);
        inheritance.deposit{value: 1 ether}();
    }

    function test_withdraw_onlyOwner() public depositinInheritance {
        vm.prank(other);
        vm.expectRevert(Inheritance.Unauthorized.selector);
        inheritance.withdraw(1 ether);
    }

    function test_withdraw_Insufficient_Amount() public depositinInheritance {
        vm.prank(owner);
        vm.expectRevert(Inheritance.InsufficientBalance.selector);
        inheritance.withdraw(1 ether + 1);
    }

    function test_withdraw_Failed() public {
        address _preComplied_black_2 = address(0x09);
        vm.prank(_preComplied_black_2);
        inheritance = new Inheritance(heir);
        vm.deal(other, 1 ether);
        vm.prank(other);
        inheritance.deposit{value: 1 ether}();
        vm.prank(_preComplied_black_2);
        vm.expectRevert(Inheritance.WithdrawalFailed.selector);
        inheritance.withdraw(1 ether);
    }

    function test_withdraw_Zero_Amount_For_last_withdrawaal_time() public depositinInheritance {
        vm.prank(owner);
        inheritance.withdraw(0);
        assertEq(inheritance.lastWithdrawalTime(), block.timestamp);
    }

    function test_withdraw_NonZero_Amount_For_last_withdrawaal_time() public depositinInheritance {
        vm.prank(owner);
        inheritance.withdraw(1 ether);
        assertEq(address(owner).balance, 1 ether); // Succefull withdrwal and time set
        assertEq(inheritance.lastWithdrawalTime(), block.timestamp);
    }

    function test_withdraw_Event() public depositinInheritance {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(inheritance));
        emit WithdrawalCompletedAndTimeUpdated(owner, 0, block.timestamp);
        inheritance.withdraw(0);
    }

    function test_claimOwnership_New_Heir_Zero_Address() public {
        vm.prank(heir);
        vm.expectRevert(Inheritance.MustBeNonZeroAddress.selector);
        inheritance.claimOwnership(address(0));
    }

    function test_claimOwnership_self_inheritance() public {
        vm.prank(heir);
        vm.expectRevert(Inheritance.OwnerAndHeirMustBeDifferent.selector);
        inheritance.claimOwnership(heir);
    }

    function test_claimOwnership_only_Heir() public {
        vm.prank(other);
        vm.expectRevert(Inheritance.Unauthorized.selector);
        inheritance.claimOwnership(heir);
    }

    function test_claimOwnership_Before_Inactivity_period() public {
        vm.prank(heir);
        vm.warp(lastWithdrawlTime + 1 days);
        vm.expectRevert(abi.encodeWithSelector(Inheritance.InactivityPeriodNotMet.selector, 1 days));
        inheritance.claimOwnership(newHeir);
    }

    function test_claimOwnership_At_Inactivity_period() public {
        vm.prank(heir);
        vm.warp(lastWithdrawlTime + 30 days);
        vm.expectRevert(abi.encodeWithSelector(Inheritance.InactivityPeriodNotMet.selector, 30 days));
        inheritance.claimOwnership(newHeir);
    }

    function test_claimOwnership_After_Inactivity_period() public {
        vm.prank(heir);
        vm.warp(lastWithdrawlTime + 31 days);
        inheritance.claimOwnership(newHeir);
        assertEq(inheritance.owner(), heir);
        assertEq(inheritance.heir(), newHeir);
        assertEq(inheritance.lastWithdrawalTime(), block.timestamp);
    }

    function test_claimOwnership_Event() public {
        vm.prank(heir);
        vm.warp(lastWithdrawlTime + 31 days);
        vm.expectEmit(true, true, true, true, address(inheritance));
        emit InheritanceStateUpdated(owner, heir, newHeir, block.timestamp);
        inheritance.claimOwnership(newHeir);
    }
}
