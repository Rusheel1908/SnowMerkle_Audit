### [H-01] `Snowman::mintSnowman` has no access control, allowing anyone to mint unlimited NFTs

**Severity:** High

**Description**

`mintSnowman` is declared as `external`, but there is no modifier or `msg.sender` check to control who can call it:

    function mintSnowman(address receiver, uint256 amount) external { 
        for (uint256 i = 0; i < amount; i++) { 
            _safeMint(receiver, s_TokenCounter); 
            emit SnowmanMinted(receiver, s_TokenCounter); 
            s_TokenCounter++; 
        } 
    }

The intended flow is for `SnowmanAirdrop` to call this function only after verifying the user's Snow balance, signature, and Merkle proof. However, `Snowman` itself does not enforce that restriction.

One thing that stood out during the review is that `error SM__NotAllowed()` is already declared at the top of the contract but is never used. This suggests that access control was likely intended but was not actually implemented.

**Impact**

Anyone can directly call `mintSnowman(receiver, amount)` and choose any `amount`.

This allows an attacker to mint an unlimited number of Snowman NFTs for free, completely bypassing the Snow-staking requirement and the signature/Merkle proof checks in `SnowmanAirdrop`.

For example, an attacker could mint 999,999 NFTs without owning any Snow tokens or providing a valid signature or Merkle proof.

This breaks the intended scarcity and access-control mechanism of the NFT.

**Proof of Concept**

    function test_H01_mintSnowman_hasNoAccessControl() public { 
        vm.prank(attacker); 
        snowman.mintSnowman(attacker, 999_999); 
        assertEq(snowman.balanceOf(attacker), 999_999); 
    }

The test passes, demonstrating that an attacker can mint 999,999 Snowman NFTs without any Snow tokens, signature, or Merkle proof.

**Recommended Mitigation**

    address private immutable i_airdropContract; 

    modifier onlyAirdrop() { 
        if (msg.sender != i_airdropContract) revert SM__NotAllowed(); 
        _; 
    } 

    function mintSnowman(address receiver, uint256 amount) external onlyAirdrop { 
        ... 
    }