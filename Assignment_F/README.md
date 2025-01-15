# Inheritance Smart Contract

This Solidity smart contract enables an “owner” to withdraw ETH and an assigned “heir” to assume ownership if the owner remains inactive (i.e., makes no withdrawals) for more than one month. The owner can also withdraw 0 ETH to reset the inactivity counter.

---

## Overview

• The contract defines an owner and an heir at deployment.  
• The owner can withdraw any amount of ETH (including 0 ETH) to reset the inactivity timer.  
• If 30 days pass without any withdrawals by the owner, the heir can call claimOwnership to take over the contract, reassign a new heir, and reset the timer.

---

## Key Features

1. **Ownership & Heir**

   - A single owner is set at deployment.
   - An heir is also set at deployment; upon the owner’s inactivity, the heir becomes the new owner.

2. **Inactivity Period Reset**

   - Owner can withdraw 0 ETH to reset the inactivity counter. This ensures they do not lose ownership inadvertently.

3. **Simple Inheritance Flow**

   - When the owner is labeled inactive, the heir can seize ownership, assign a new heir, and maintain or distribute funds as needed.

4. **Transparent Events**
   - All deposits and withdrawals are recorded via events for on-chain transparency.

---

## Design Decisions

1. **Initial Heir Assignment**

   - The heir address must be non-zero at contract creation to avoid “stuck” ownership without inheritance capability.

2. **One-Month Timeout**

   - The inactivity period is set to 30 days (30 × 24 × 60 × 60 seconds).

3. **Heir Not Equal to Owner**

   - The contract prohibits setting the heir to the same address as the owner at deployment. This eliminates trivial self-inheritance and preserves the logic that the heir is a distinct party.

4. **Timestamp Comparisons**

   - The contract uses block timestamps to measure periods of inactivity. While it is a known best practice to avoid relying heavily on block timestamps for strict time logic, this approach is generally acceptable for a 30-day window because block timestamp manipulation is infeasible on this large scale.

5. **Low-Level Call for Withdrawal**

   - The contract uses a low-level call when transferring out funds. This is to allow for flexibility in sending ETH. Despite Slither’s notification, it is purposeful here and controlled within the contract.

6. **Solidity Compiler Version (0.8.20)**

   - The contract uses Solidity 0.8.20. Notably, 0.8.20 can generate bytecode containing the PUSH0 opcode (EVM version “Shanghai”).

7. **Funds Potentially Remaining in the Contract**
   - Once the contract is deployed, the owner or heir can deposit and withdraw ETH. If the heir address is set to a contract that cannot receive ETH properly, the funds might get stuck if that contract cannot handle ETH transfers. This is an unavoidable risk at the caller’s discretion.

---

## Known Issues & Their Impact

During static analysis (via Slither), the following items were reported:

1. **Block Timestamp Comparison**

   - Slither flagged “timeElapsed <= INACTIVITY_PERIOD.”
   - This is typical for time-based logic. As stated, while block timestamps can have minimal manipulation per block, the risk is negligible over a 30-day period.

2. **Low-Level Call**

   - Slither warns about using .call(). We use this intentionally to allow dynamic invocation. We do handle errors by reverting on failed calls.

3. **PUSH0 Opcode & EVM Compatibility** (L-4)
   - Solidity 0.8.20 targets the Shanghai fork by default. Some Layer-2 solutions or test networks might not support it yet.

Overall, while these issues are worth noting, they are not critical for our intended functionality. They can be mitigated or accepted with proper awareness of the trade-offs.

---

## Testing & Coverage

If you have Foundry installed, you can easily test and check coverage:

• Run all tests: `forge test`

• Check coverage: `forge coverage`

• We have 100% coverage in our test suite.

• Some important invariants verified by our tests include:

1. statefulFuzz_Non_Zero_Owner()

   - Ensures the owner is never the zero address.

2. statefulFuzz_Non_Zero_Heir()

   - Ensures the heir is never the zero address.

3. statefulFuzz_Owner_is_Heir()

   - Ensures owner and heir are not the same.

4. statefulFuzz_lastWithdrawal_time_is_non_zero()

   - Ensures lastWithdrawalTime is initialized (non-zero).

5. statefulFuzz_lastWithdrawal_time_is_not_in_Future()
   - Ensures lastWithdrawalTime is never ahead of the current block timestamp.

---

## Deployment Instructions

Below is a sample Foundry command to deploy the contract to a network (for example, Sepolia).
Replace $SEPOLIA_URL and account0 with your actual RPC endpoint and private key or key alias:

`forge script ./script/Inheritance.s.sol --rpc-url=$SEPOLIA_URL --account account0 --broadcast`

Notes:
• The heir address is currently hard-coded in the script (./script/Inheritance.s.sol).  
• We assume you have a valid private key or wallet import under the alias “account0.”  
• $SEPOLIA_URL is public RPC URL for Sepolia testnet.
