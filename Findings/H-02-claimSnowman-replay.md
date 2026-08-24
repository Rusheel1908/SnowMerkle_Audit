### [H-02] `SnowmanAirdrop::claimSnowman` can be called repeatedly with the same signature and proof

**Severity:** High

**Description**

`claimSnowman` sets `s_hasClaimedSnowman[receiver] = true` after a successful claim, but the mapping is never checked before allowing another claim:

    function claimSnowman(address receiver, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) 
        external 
        nonReentrant 
    { 
        ... 
        s_hasClaimedSnowman[receiver] = true;
        ... 
        i_snowman.mintSnowman(receiver, amount); 
    }

This stood out during the review because the contract keeps track of whether a receiver has already claimed, but never uses that information to prevent another claim.

Since `Snow` can be earned again every week through `earnSnow()`, the receiver's Snow balance can become non-zero again over time. The original `v, r, s` signature and Merkle proof also remain valid because neither is invalidated or marked as used after the first claim.

**Impact**

A user can potentially claim additional Snowman NFTs every time they earn Snow again by reusing the same signature and Merkle proof from their original claim.

The `s_hasClaimedSnowman` mapping strongly suggests that the intended behavior was to allow each eligible address to claim only once. Because the mapping is only written and never checked, that restriction is not actually enforced.

This can result in repeated NFT minting over time for an address that has already claimed.

**Proof of Concept**

_Pending — requires deploying `Snow` and `SnowmanAirdrop` together, generating a valid Merkle tree/proof, and creating a valid signature to produce `v, r, s`._

**Recommended Mitigation**

Check whether the receiver has already claimed before continuing:

    if (s_hasClaimedSnowman[receiver]) { 
        revert SA__AlreadyClaimed(); 
    } 
    ... 
    s_hasClaimedSnowman[receiver] = true;