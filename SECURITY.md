# Security Policy

## Scope

This repository is a portfolio-grade prototype for a milestone-based stablecoin escrow flow. It is intended to demonstrate smart contract design, testing, frontend product thinking, and security awareness.

It has not been audited and should not be used to custody real funds without additional review.

## Current Assumptions

- The escrow token behaves like a standard ERC-20 and returns `true` on successful transfers.
- The client, freelancer, and arbiter addresses are known before deployment.
- The arbiter is trusted to resolve disputes fairly.
- Milestone evidence is represented by hashes; evidence storage and identity checks are outside the current contract.

## Known Gaps Before Production

- Replace raw ERC-20 calls with OpenZeppelin `SafeERC20`.
- Add explicit deadline and timeout rules for stalled projects.
- Add factory deployment and per-escrow metadata events.
- Add EIP-712 signed approvals for milestone evidence and settlement terms.
- Add richer dispute evidence events with content-addressed document hashes.
- Add fuzz tests, invariant tests, and fork tests against real stablecoin behavior.
- Complete an external audit before handling real value.

## Reporting

For portfolio review feedback or security notes, open a GitHub issue or contact the maintainer through the profile README.
