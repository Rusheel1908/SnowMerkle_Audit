# Snowman Merkle Airdrop — Security Review

This is my independent security review of the Snowman Merkle Airdrop protocol from Cyfrin/CodeHawks First Flight.

I reviewed the three main contracts: `Snow.sol`, `Snowman.sol`, and `SnowmanAirdrop.sol`. The goal of this review was to understand the protocol, identify potential security issues, and build proof-of-concepts where possible.

This was done as a self-directed learning exercise after the original contest had ended, so this is **not an official CodeHawks submission**.

## Scope

| File | Reviewed |
|---|---|
| `src/Snow.sol` | Yes |
| `src/Snowman.sol` | Yes |
| `src/SnowmanAirdrop.sol` | Yes |

Mocks and test/deployment scripts were not included in the review.

## Findings

| ID | Finding | Severity | PoC |
|---|---|---|---|
| H-01 | `Snowman::mintSnowman` has no access control | High | ✅ Completed |
| H-02 | `SnowmanAirdrop::claimSnowman` allows signature/proof replay | High | 🔲 In progress |
| H-03 | `Snow::earnSnow` uses one shared timer instead of tracking users individually | High | 🔲 In progress |

## Notes

This review represents my current understanding of the contracts and the issues I was able to identify during the exercise. I am still working on reproducing and validating some of the findings through Foundry-based PoCs.

This is a learning exercise and should not be considered a professional security audit or a guarantee that the contracts contain no other vulnerabilities.  