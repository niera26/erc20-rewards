// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {ERC20RewardsTest} from "./ERC20RewardsTest.t.sol";

contract OperatorTest is ERC20RewardsTest {
    function testSetOperator() public {
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);
        address user3 = vm.addr(3);

        // by default operator is owner.
        assertEq(token.operator(), address(this));

        // set an operator.
        token.setOperator(user1);

        assertEq(token.operator(), user1);

        // owner now reverts.
        vm.expectRevert("!operator");

        token.setOperator(user3);

        // user reverts.
        vm.prank(user2);

        vm.expectRevert("!operator");

        token.setOperator(user3);

        // zero address reverts.
        vm.prank(user1);

        vm.expectRevert("!address");

        token.setOperator(address(0));

        // operator can set operator.
        vm.prank(user1);

        token.setOperator(user2);

        assertEq(token.operator(), user2);
    }

    function testSetPoolFee() public {
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        // by default the pool fee is 10000.
        assertEq(token.poolFee(), 10000);

        // set an operator.
        token.setOperator(user1);

        assertEq(token.operator(), user1);

        // owner now revert.
        vm.expectRevert("!operator");

        token.setPoolFee(4000);

        // non operator reverts.
        vm.prank(user2);

        vm.expectRevert("!operator");

        token.setPoolFee(4000);

        // operator can set pool fee.
        vm.prank(user1);

        token.setPoolFee(3000);

        assertEq(token.poolFee(), 3000);
    }

    function testSetRewardTokenPerBlock() public {
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        // by default the reward token per block is 0.
        assertEq(token.rewardTokenPerBlock(), 0);

        // set an operator.
        token.setOperator(user1);

        assertEq(token.operator(), user1);

        // owner now revert.
        vm.expectRevert("!operator");

        token.setRewardTokenPerBlock(2000);

        // non operator reverts.
        vm.prank(user2);

        vm.expectRevert("!operator");

        token.setRewardTokenPerBlock(2000);

        // operator can set reward token per block.
        vm.prank(user1);

        token.setRewardTokenPerBlock(3000);

        assertEq(token.rewardTokenPerBlock(), 3000);
    }

    function testRemoveLimits() public {
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        // by default max wallet is 1% of the supply.
        assertEq(token.maxWallet(), token.totalSupply() / 100);

        // set new operator.
        token.setOperator(user1);

        // owner cant remove limits.
        vm.expectRevert();

        token.removeMaxWallet();

        // non operator cant remove limits.
        vm.prank(user2);

        vm.expectRevert();

        token.removeMaxWallet();

        // operator can remove limits.
        vm.prank(user1);

        token.removeMaxWallet();

        assertEq(token.maxWallet(), type(uint256).max);
    }
}
