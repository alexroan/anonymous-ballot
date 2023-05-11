# GovernorZK - Anonymized OnChain Governance

GovernorZK is a ZK implementation of OpenZeppelin's `Governor` contract, built to resemble Compound Finance's `GovernorBravo` contract. It anonymizes voting on proposals by severing the link between voter and vote, using a Nullifiable ZK Merkle Tree pioneered by Tornado Cash.

## Simple Example

- Patrick is 1 of 5 public members of a DAO. The DAO want their voting directions to be kept hidden, but the final result to be public.
- A proposal is made to the GovernorZK contract.
- **COMMITMENT PHASE**
- Patrick wishes to vote on this proposal so he creates a `secret` and a `nullifier` locally, which he uses to generate a `commitment`. To register to vote, he sends this `commitment` to the contract from his known public address. The contract checks that the `commitment` is sent from Patrick's known address, and stores it. Every DAO member who wishes to participate in this proposal vote does this.
- **VOTING PHASE**
- Using ZK proofs, each DAO member can now vote anonymously from anonymous accounts by proving that they know a `commitment` without having to provide that `commitment` to the contract. Instead, they provide a ZK-proof that they know it, and their vote.

The link between Patrick's allow-listed address and the vote he casts is severed in the same way that the link between depositor and withdrawer is severed in Tornado Cash.

## Current limitations

- 1 token = 1 vote doesn't work here as it risks giving away the identity of the voter. GovernorZK currently supports 1 allow-listed account = 1 vote, however, it is outsourced using the `IVotes` interface as defined by Openzeppelin. Some ideas on this:
  - Soulbound voting works well here, as well as rules like "Any balance above 0 = 1 vote" (NFTs for example)/
  - This could be expanded by supporting tranches of votes (1, 10, 100, 1000, etc), similar to Tornado cash
- The Merkle Tree size is fixed to a height of 20 (2^20 leaves). Could we make this flexible depending on the use case?
- Foundry support is lacking given that most ZK libraries are written in JS/TS. Wen Ripped Jesus?