// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {ERC20RewardsTest} from "./ERC20RewardsTest.t.sol";

contract BlacklistTest is ERC20RewardsTest {
    function testDeadblocks() public {
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);
        address user3 = vm.addr(3);

        // n block is a dead block.
        vm.roll(token.startBlock());

        buyToken(user1, 1 ether);

        assertTrue(token.isBlacklisted(user1));
        assertGt(token.balanceOf(user1), 0);

        // n + 1 block is a dead block.
        vm.roll(token.startBlock() + 1);

        buyToken(user2, 1 ether);

        assertTrue(token.isBlacklisted(user2));
        assertGt(token.balanceOf(user2), 0);

        // n + 2 is ok.
        vm.roll(token.startBlock() + 2);

        buyToken(user3, 1 ether);

        assertFalse(token.isBlacklisted(user3));
        assertGt(token.balanceOf(user3), 0);

        assertEq(token.balanceOf(user1), 0); // blacklisted user balance is soft burned
        assertEq(token.balanceOf(user2), 0); // blacklisted user balance is soft burned
        assertGt(token.lockedBalanceOf(user1), 0); // raw balance is still available
        assertGt(token.lockedBalanceOf(user2), 0); // raw balance is still available

        // total supply is soft burned.
        assertEq(token.totalSupply(), token.initialSupply() - token.blacklistedSupply());

        // blacklisted supply is locked balance of user1 and user2.
        assertEq(token.blacklistedSupply(), token.lockedBalanceOf(user1) + token.lockedBalanceOf(user2));

        // total shares are only user3.
        assertEq(token.totalShares(), token.balanceOf(user3));
    }

    function testRemoveFromBlacklist() public {
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        // blacklist user1.
        vm.roll(token.startBlock());

        buyToken(user1, 1 ether);

        uint256 balance1 = token.balanceOf(user1);

        assertTrue(token.isBlacklisted(user1));
        assertGt(token.balanceOf(user1), 0); // show the actual balance until the trading starts (uniswap accept swaps).
        assertEq(token.totalShares(), 0);
        assertEq(token.lockedBalanceOf(user1), balance1);
        assertEq(token.blacklistedSupply(), balance1);
        assertEq(token.totalSupply(), token.initialSupply() - balance1);

        // user2 buys.
        vm.roll(token.startBlock() + token.deadBlocks() + 1);

        buyToken(user2, 1 ether);

        uint256 balance2 = token.balanceOf(user2);

        // trading started so user1 balance is locked.
        assertTrue(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), 0);
        assertGt(token.balanceOf(user2), 0);
        assertEq(token.totalShares(), balance2);
        assertEq(token.lockedBalanceOf(user1), balance1);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), balance1);
        assertEq(token.totalSupply(), token.initialSupply() - balance1);

        // remove from blacklist reverts for non owner.
        vm.prank(user2);

        vm.expectRevert();

        token.removeFromBlacklist(user1);

        // owner can remove from blacklist.
        token.removeFromBlacklist(user1);

        assertFalse(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), balance1);
        assertEq(token.balanceOf(user2), balance2);
        assertEq(token.totalShares(), balance1 + balance2);
        assertEq(token.lockedBalanceOf(user1), 0);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), 0);
        assertEq(token.totalSupply(), token.initialSupply());

        // can remove many times from blacklist.
        token.removeFromBlacklist(user1);

        assertFalse(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), balance1);
        assertEq(token.balanceOf(user2), balance2);
        assertEq(token.totalShares(), balance1 + balance2);
        assertEq(token.lockedBalanceOf(user1), 0);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), 0);
        assertEq(token.totalSupply(), token.initialSupply());
    }

    function testBlacklistTransfer() public {
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        // blacklist user1.
        vm.roll(token.startBlock());

        buyToken(user1, 1 ether);

        uint256 balance1 = token.balanceOf(user1);

        assertTrue(token.isBlacklisted(user1));
        assertGt(token.balanceOf(user1), 0); // show the actual balance until the trading starts (uniswap accept swaps).
        assertEq(token.totalShares(), 0);
        assertEq(token.lockedBalanceOf(user1), balance1);
        assertEq(token.blacklistedSupply(), balance1);
        assertEq(token.totalSupply(), token.initialSupply() - balance1);

        // user2 buys.
        vm.roll(token.startBlock() + token.deadBlocks() + 1);

        buyToken(user2, 1 ether);

        uint256 balance2 = token.balanceOf(user2);

        // trading started so user1 balance is locked.
        assertTrue(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), 0);
        assertGt(token.balanceOf(user2), 0);
        assertEq(token.totalShares(), balance2);
        assertEq(token.lockedBalanceOf(user1), balance1);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), balance1);
        assertEq(token.totalSupply(), token.initialSupply() - balance1);

        // keep half of user2 balance.
        uint256 half = balance2 / 2;

        assertGt(half, 0);

        // blacklisted user can still receive tokens.
        vm.prank(user2);

        token.transfer(user1, half);

        assertTrue(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), balance2 - half);
        assertEq(token.totalShares(), balance2 - half);
        assertEq(token.lockedBalanceOf(user1), balance1 + half);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), balance1 + half);
        assertEq(token.totalSupply(), token.initialSupply() - balance1 - half);

        // blacklisted user can still receive tokens with transfered from.
        vm.prank(user2);

        token.approve(address(this), half);

        token.transferFrom(user2, user1, half);

        assertTrue(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(user2), balance2 - half * 2);
        assertEq(token.totalShares(), balance2 - half * 2);
        assertEq(token.lockedBalanceOf(user1), balance1 + half * 2);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), balance1 + half * 2);
        assertEq(token.totalSupply(), token.initialSupply() - balance1 - half * 2);

        // blacklisted user can't send tokens anymore.
        vm.prank(user1);

        vm.expectRevert("blacklisted");

        token.transfer(user2, half);

        // blacklisted user can't send with a transfer from.
        vm.prank(user1);

        token.approve(address(this), half);

        vm.expectRevert("blacklisted");

        token.transferFrom(user1, user2, half);

        // remove user1 from blacklist.
        token.removeFromBlacklist(user1);

        assertFalse(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), balance1 + half * 2);
        assertEq(token.balanceOf(user2), balance2 - half * 2);
        assertEq(token.totalShares(), balance1 + balance2);
        assertEq(token.lockedBalanceOf(user1), 0);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), 0);
        assertEq(token.totalSupply(), token.initialSupply());

        // user1 can send tokens again.
        vm.prank(user1);

        token.transfer(user2, half);

        assertFalse(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), balance1 + half);
        assertEq(token.balanceOf(user2), balance2 - half);
        assertEq(token.totalShares(), balance1 + balance2);
        assertEq(token.lockedBalanceOf(user1), 0);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), 0);
        assertEq(token.totalSupply(), token.initialSupply());

        // user1 can send from a transfer from again.
        vm.prank(user1);

        token.approve(address(this), half);

        token.transferFrom(user1, user2, half);

        assertFalse(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), balance1);
        assertEq(token.balanceOf(user2), balance2);
        assertEq(token.totalShares(), balance1 + balance2);
        assertEq(token.lockedBalanceOf(user1), 0);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), 0);
        assertEq(token.totalSupply(), token.initialSupply());
    }

    function testBlacklistDistribution() public {
        address user1 = vm.addr(1);
        address user2 = vm.addr(2);

        // blacklist user1.
        vm.roll(token.startBlock());

        buyToken(user1, 1 ether);

        uint256 balance1 = token.balanceOf(user1);

        assertTrue(token.isBlacklisted(user1));
        assertGt(token.balanceOf(user1), 0); // show the actual balance until the trading starts (uniswap accept swaps).
        assertEq(token.totalShares(), 0);
        assertEq(token.lockedBalanceOf(user1), balance1);
        assertEq(token.blacklistedSupply(), balance1);
        assertEq(token.totalSupply(), token.initialSupply() - balance1);

        // user2 buys.
        vm.roll(token.startBlock() + token.deadBlocks() + 1);

        buyToken(user2, 1 ether);

        uint256 balance2 = token.balanceOf(user2);

        // trading started so user1 balance is locked.
        assertTrue(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertEq(token.balanceOf(user1), 0);
        assertGt(token.balanceOf(user2), 0);
        assertEq(token.totalShares(), balance2);
        assertEq(token.lockedBalanceOf(user1), balance1);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), balance1);
        assertEq(token.totalSupply(), token.initialSupply() - balance1);

        // distribute the current rewards.
        token.swapCollectedTax(0);
        token.distribute(0);

        // only user2 has rewards.
        uint256 pendingRewards1 = token.pendingRewards(user1);
        uint256 pendingRewards2 = token.pendingRewards(user2);

        assertEq(pendingRewards1, 0);
        assertGt(pendingRewards2, 0);

        // remove user1 from blacklist.
        token.removeFromBlacklist(user1);

        assertFalse(token.isBlacklisted(user1));
        assertFalse(token.isBlacklisted(user2));
        assertGt(token.balanceOf(user1), 0);
        assertGt(token.balanceOf(user2), 0);
        assertEq(token.totalShares(), balance1 + balance2);
        assertEq(token.lockedBalanceOf(user1), 0);
        assertEq(token.lockedBalanceOf(user2), 0);
        assertEq(token.blacklistedSupply(), 0);
        assertEq(token.totalSupply(), token.initialSupply());

        // add rewards and distribute and distribute.
        addRewards(1 ether);

        token.distribute(0);

        // user1 now has rewards.
        assertGt(token.pendingRewards(user1), 0);
        assertGt(token.pendingRewards(user2), pendingRewards2);
    }
}
