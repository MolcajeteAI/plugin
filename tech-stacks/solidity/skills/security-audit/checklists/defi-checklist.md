# DeFi Security Checklist

Security checklist for DeFi protocols including AMMs, lending, staking, and yield farming contracts.

## Price Oracle Security

### Oracle Implementation
- [ ] Multiple oracle sources (Chainlink preferred)
- [ ] Price staleness checks
- [ ] Heartbeat validation
- [ ] Circuit breakers for extreme price movements
- [ ] Fallback oracle mechanism

**Staleness Check:**
```solidity
(, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
require(block.timestamp - updatedAt < 1 hours, "Stale price");
require(price > 0, "Invalid price");
```

### Oracle Manipulation

**Flash Loan Attacks:**
- [ ] TWAP (Time-Weighted Average Price) used
- [ ] Multi-block price averaging
- [ ] Price deviation limits
- [ ] No single-block price reliance

**Spot Price Manipulation:**
- [ ] Don't use spot price for critical decisions
- [ ] Reserve ratio checks
- [ ] Liquidity depth validation
- [ ] Multi-block TWAP or Chainlink

**Vulnerable Pattern:**
```solidity
// ❌ Spot price manipulation
uint256 price = reserve1 / reserve0;  // Can be manipulated in same block
uint256 collateral = userDeposit * price;
```

**Secure Pattern:**
```solidity
// ✅ Chainlink with staleness check
AggregatorV3Interface priceFeed;
(, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
require(block.timestamp - updatedAt < 3600, "Stale price");
uint256 collateral = userDeposit * uint256(price);
```

### Price Deviation
- [ ] Maximum price change per update enforced
- [ ] Circuit breaker triggers on extreme moves
- [ ] Manual override for emergencies
- [ ] Historical price comparison

## Flash Loan Protection

### Attack Vectors
- [ ] Price manipulation via flash loans
- [ ] Governance manipulation
- [ ] Liquidity drainage
- [ ] Arbitrage exploitation

### Protection Mechanisms
- [ ] Multi-block requirements for critical operations
- [ ] TWAP instead of spot prices
- [ ] Deposit/withdrawal delays
- [ ] Reentrancy guards
- [ ] Balance change detection

**Balance Check Pattern:**
```solidity
uint256 balanceBefore = token.balanceOf(address(this));
// External call
uint256 balanceAfter = token.balanceOf(address(this));
require(balanceAfter >= balanceBefore, "Unexpected balance decrease");
```

## AMM/DEX Security

### Liquidity Pool

**Reserves:**
- [ ] Reserve accounting accurate
- [ ] K (constant product) maintained
- [ ] Minimum liquidity enforced
- [ ] No reserve draining attacks

**Swaps:**
- [ ] Slippage protection enforced
- [ ] Deadline parameter checked
- [ ] Price impact calculated correctly
- [ ] No sandwich attack vulnerabilities
- [ ] Sufficient liquidity checks

```solidity
function swap(
    uint256 amountIn,
    uint256 minAmountOut,
    uint256 deadline
) public {
    require(block.timestamp <= deadline, "Expired");
    uint256 amountOut = getAmountOut(amountIn);
    require(amountOut >= minAmountOut, "Slippage too high");
    // Perform swap
}
```

### Liquidity Provision

**Add Liquidity:**
- [ ] Optimal ratio calculated correctly
- [ ] Slippage protection
- [ ] First liquidity provider protected
- [ ] Minimum liquidity locked
- [ ] LP tokens minted correctly

**Remove Liquidity:**
- [ ] Burns LP tokens correctly
- [ ] Returns correct token amounts
- [ ] No rounding errors
- [ ] Proportional withdrawal

### Fee Management

- [ ] Fee calculation correct
- [ ] Fee distribution fair
- [ ] Protocol fees tracked accurately
- [ ] No fee manipulation
- [ ] Fee changes have timelock

## Lending Protocol Security

### Collateralization

**Health Factor:**
- [ ] Health factor calculation correct
- [ ] Liquidation threshold appropriate
- [ ] Oracle prices used correctly
- [ ] Collateral factor safe (< 100%)

```solidity
healthFactor = (collateralValue * liquidationThreshold) / borrowedValue;
require(healthFactor >= 1e18, "Undercollateralized");
```

**Collateral Management:**
- [ ] Collateral deposit tracked correctly
- [ ] Collateral types validated
- [ ] Multiple collateral types handled
- [ ] Collateral values updated

### Borrowing

**Borrow Limits:**
- [ ] Utilization ratio enforced
- [ ] Borrow capacity checked
- [ ] Interest calculated correctly
- [ ] Debt tracking accurate

**Interest Rates:**
- [ ] Interest rate model sound
- [ ] Compound interest correctly calculated
- [ ] Rate updates non-exploitable
- [ ] No overflow in interest calculations

### Liquidations

**Liquidation Logic:**
- [ ] Liquidation threshold appropriate (typically 75-85%)
- [ ] Liquidation bonus reasonable (5-10%)
- [ ] Partial liquidations allowed
- [ ] Bad debt handling mechanism
- [ ] Liquidation can't be frontrun to harm protocol

**Liquidation Protection:**
- [ ] Grace period before liquidation
- [ ] Price manipulation protection
- [ ] Flash loan liquidation protected
- [ ] Self-liquidation prevented (if applicable)

## Staking Protocol Security

### Stake Management

**Deposits:**
- [ ] Stake accounting correct
- [ ] Receipt tokens issued correctly
- [ ] No loss of user funds
- [ ] Reentrancy protection

**Withdrawals:**
- [ ] Withdrawal delays enforced (if applicable)
- [ ] Correct amount returned
- [ ] Slashing applied correctly
- [ ] Reentrancy protection

### Rewards

**Reward Calculation:**
- [ ] Reward distribution fair
- [ ] Pro-rata calculation correct
- [ ] No rounding errors favoring any party
- [ ] Reward rate updates handled correctly

**Reward Distribution:**
- [ ] Compound rewards optional
- [ ] Claim doesn't affect others
- [ ] Reward inflation controlled
- [ ] Emergency withdrawal preserves rewards

```solidity
// Per-token accounting pattern
uint256 rewardPerTokenStored;

function earned(address account) public view returns (uint256) {
    return
        (balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 +
        rewards[account];
}
```

### Slashing

- [ ] Slashing conditions clear
- [ ] Slashing amount reasonable
- [ ] User notification mechanism
- [ ] Appeal process (if applicable)
- [ ] No accidental total slashing

## Yield Farming Security

### Vault/Strategy

**Deposit/Withdrawal:**
- [ ] Share calculation correct
- [ ] PPS (Price Per Share) manipulation protected
- [ ] First depositor attack prevented
- [ ] Withdrawal fees reasonable

**Strategy Execution:**
- [ ] Strategy authorized
- [ ] Yield source validated
- [ ] Harvest timing safe
- [ ] Compounding works correctly
- [ ] Emergency withdrawal available

### Auto-Compounding

**Compound Logic:**
- [ ] Rewards harvested correctly
- [ ] Reinvestment amount correct
- [ ] Gas costs considered
- [ ] Harvest timing optimal
- [ ] MEV protection

**Share Inflation:**
- [ ] Donation attack protected
- [ ] First depositor gets fair shares
- [ ] No precision loss attacks
- [ ] Share price manipulation impossible

## Governance Security

### Proposal System

**Proposal Creation:**
- [ ] Proposal threshold appropriate
- [ ] Malicious proposals prevented
- [ ] Proposal validation
- [ ] Proposal queue limits

**Voting:**
- [ ] Voting power calculated correctly
- [ ] Snapshot mechanism prevents flash loan votes
- [ ] Delegation works correctly
- [ ] Vote buying mitigated
- [ ] Quorum requirements reasonable

**Execution:**
- [ ] Timelock enforced
- [ ] Execution validation
- [ ] Failed execution handling
- [ ] No unauthorized execution

### Timelock

- [ ] Minimum delay appropriate (24-48 hours)
- [ ] Emergency functions bypass with multi-sig
- [ ] Pending operations transparent
- [ ] Cancellation mechanism exists

## Token Economics

### Supply Management

**Inflation:**
- [ ] Inflation rate documented
- [ ] Emission schedule clear
- [ ] Max supply enforced (if applicable)
- [ ] Inflation control mechanisms

**Deflation:**
- [ ] Burn mechanism documented
- [ ] Burn rate reasonable
- [ ] No accidental burns
- [ ] Supply tracking accurate

### Vesting

**Vesting Schedule:**
- [ ] Vesting periods appropriate
- [ ] Cliff periods enforced
- [ ] Linear vs stepped vesting clear
- [ ] Vesting can't be gamed

**Token Claims:**
- [ ] Claim calculations correct
- [ ] Can claim partial amounts
- [ ] Unclaimed tokens handled
- [ ] Transfer of vesting rights (if applicable)

## Cross-Chain Bridge Security

### Bridge Operations

**Lock/Mint:**
- [ ] Tokens locked correctly
- [ ] Mint authorization validated
- [ ] 1:1 backing maintained
- [ ] No double minting

**Burn/Unlock:**
- [ ] Burn verified before unlock
- [ ] Unlock amount correct
- [ ] Fees handled correctly
- [ ] Reentrancy protection

### Bridge Security

- [ ] Multi-sig for bridge operations
- [ ] Bridge balance monitoring
- [ ] Pause mechanism exists
- [ ] Rate limiting for large transfers
- [ ] Chain ID validation
- [ ] Nonce management

## Common DeFi Vulnerabilities

### High Risk

1. **Oracle Manipulation**
   - Flash loan price manipulation
   - Spot price reliance
   - Stale price data

2. **Liquidation Issues**
   - Bad debt accumulation
   - Liquidation cascades
   - Insufficient liquidity

3. **Reward Manipulation**
   - Donation attacks
   - Share price manipulation
   - Flash loan reward gaming

### Medium Risk

1. **Front-Running**
   - MEV exploitation
   - Sandwich attacks
   - Liquidation front-running

2. **Integration Risks**
   - Composability issues
   - External protocol failures
   - Token compatibility

## Testing Requirements

### Unit Tests

- [ ] Price oracle edge cases
- [ ] Liquidation scenarios
- [ ] Reward calculations
- [ ] Flash loan attacks
- [ ] Slippage protection

### Integration Tests

- [ ] External protocol interactions
- [ ] Multi-block scenarios
- [ ] Extreme market conditions
- [ ] Oracle failures
- [ ] Liquidity drains

### Fuzzing

- [ ] Random deposit/withdrawal amounts
- [ ] Random price movements
- [ ] Random user actions
- [ ] Invariant testing (TVL, shares, etc.)

## Quick Reference

| Protocol Type | Key Risks |
|--------------|-----------|
| AMM/DEX | Price manipulation, sandwich attacks, liquidity drainage |
| Lending | Oracle manipulation, bad debt, liquidation cascades |
| Staking | Reward calculation errors, slashing bugs |
| Yield Farming | Share price manipulation, strategy risks |
| Governance | Flash loan voting, malicious proposals |

---

**Remember:** DeFi protocols are composable, meaning vulnerabilities can cascade across protocols. Test interactions with external contracts thoroughly.
