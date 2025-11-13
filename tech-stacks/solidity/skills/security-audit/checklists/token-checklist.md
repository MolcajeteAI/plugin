# Token Security Checklist

Security checklist for ERC20, ERC721, and ERC1155 token implementations.

## ERC20 Token Checklist

### Standard Compliance
- [ ] Implements all required ERC20 functions
- [ ] Implements all required ERC20 events
- [ ] Function signatures match standard
- [ ] Returns correct types
- [ ] Follows ERC20 behavior specifications

**Required functions:**
- [ ] `totalSupply()` - Returns total supply
- [ ] `balanceOf(address)` - Returns balance
- [ ] `transfer(address, uint256)` - Transfers tokens
- [ ] `allowance(address, address)` - Returns allowance
- [ ] `approve(address, uint256)` - Approves spending
- [ ] `transferFrom(address, address, uint256)` - Transfers on behalf

**Required events:**
- [ ] `Transfer(address indexed from, address indexed to, uint256 value)`
- [ ] `Approval(address indexed owner, address indexed spender, uint256 value)`

### Transfer Security

**Basic Transfers:**
- [ ] Zero address checks on transfers
- [ ] Balance checks before transfer
- [ ] Balance updates use safe math (0.8+)
- [ ] Transfer events emitted
- [ ] Self-transfers handled correctly

**Transfer Return Values:**
- [ ] `transfer()` returns bool
- [ ] `transferFrom()` returns bool
- [ ] Returns true on success
- [ ] Reverts on failure (don't return false)

```solidity
// ✅ Good: Revert on failure
function transfer(address to, uint256 amount) public returns (bool) {
    require(to != address(0), "Invalid recipient");
    require(balanceOf[msg.sender] >= amount, "Insufficient balance");

    balanceOf[msg.sender] -= amount;
    balanceOf[to] += amount;

    emit Transfer(msg.sender, to, amount);
    return true;
}
```

### Approval Mechanism

**Approval Race Condition:**
- [ ] Users aware of race condition
- [ ] Documentation mentions issue
- [ ] Consider increaseAllowance/decreaseAllowance
- [ ] Check-and-set pattern not used

**Race condition explained:**
1. Alice approves Bob for 100 tokens
2. Alice wants to change to 50 tokens
3. Bob sees transaction, quickly spends 100
4. Alice's transaction sets allowance to 50
5. Bob can now spend another 50 (150 total!)

**Mitigation:**
```solidity
// ✅ Provide safe alternatives
function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
    return true;
}

function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    uint256 currentAllowance = allowance[msg.sender][spender];
    require(currentAllowance >= subtractedValue, "Decreased below zero");
    _approve(msg.sender, spender, currentAllowance - subtractedValue);
    return true;
}
```

### Supply Management

**Minting:**
- [ ] Minting restricted to authorized addresses
- [ ] Supply cap enforced (if applicable)
- [ ] Mint amount validation
- [ ] Zero address check on mint
- [ ] Events emitted

**Burning:**
- [ ] Users can burn own tokens
- [ ] Balance check before burn
- [ ] Supply decreased correctly
- [ ] Events emitted with zero address

**Supply Tracking:**
- [ ] totalSupply accurate
- [ ] Mint increases supply
- [ ] Burn decreases supply
- [ ] No arithmetic errors

### Decimal Handling

- [ ] Decimals defined (usually 18)
- [ ] Decimals() function present
- [ ] Calculations account for decimals
- [ ] No precision loss issues
- [ ] Documentation clear on decimal usage

### Fee-on-Transfer Tokens

If implementing fee mechanism:
- [ ] Fee calculation correct
- [ ] Fee not applied twice
- [ ] Transfer amount vs received amount clear
- [ ] Fee destination specified
- [ ] Events show correct amounts
- [ ] Compatible with protocols expecting standard ERC20

**Issues to avoid:**
```solidity
// ❌ Many protocols assume:
contract.transfer(recipient, 100);
assert(recipient.balanceOf() == previousBalance + 100);  // FAILS with fee-on-transfer!
```

### Permit (EIP-2612)

If implementing permit:
- [ ] EIP-712 correctly implemented
- [ ] Domain separator correct
- [ ] Nonce management proper
- [ ] Deadline enforced
- [ ] Signature verification secure
- [ ] Replay protection present

## ERC721 (NFT) Checklist

### Standard Compliance
- [ ] Implements required ERC721 functions
- [ ] Implements ERC721Metadata (recommended)
- [ ] Implements ERC721Enumerable (if needed)
- [ ] Implements ERC165 for interface detection
- [ ] Returns correct types
- [ ] Events emitted properly

**Required functions:**
- [ ] `balanceOf(address)` - Count of NFTs
- [ ] `ownerOf(uint256)` - Owner of token ID
- [ ] `safeTransferFrom(address, address, uint256)` - Safe transfer
- [ ] `transferFrom(address, address, uint256)` - Transfer
- [ ] `approve(address, uint256)` - Approve token
- [ ] `setApprovalForAll(address, bool)` - Approve operator
- [ ] `getApproved(uint256)` - Get approved address
- [ ] `isApprovedForAll(address, address)` - Check operator

### Safe Transfer

**SafeTransferFrom Implementation:**
- [ ] Checks receiver implements ERC721Receiver
- [ ] Calls onERC721Received on receiver
- [ ] Validates receiver return value
- [ ] Reverts if receiver doesn't accept
- [ ] Protects against sending to contracts that can't handle NFTs

```solidity
// ✅ Safe transfer checks receiver
function safeTransferFrom(address from, address to, uint256 tokenId) public {
    transferFrom(from, to, tokenId);

    require(
        to.code.length == 0 ||
        ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, "") ==
        ERC721TokenReceiver.onERC721Received.selector,
        "Unsafe recipient"
    );
}
```

### Ownership and Approvals

**Ownership Tracking:**
- [ ] ownerOf() accurate
- [ ] Zero address not an owner
- [ ] Token IDs unique
- [ ] Transfers update ownership
- [ ] Burns clear ownership

**Approval Management:**
- [ ] Approve restricted to owner/operator
- [ ] Approvals cleared on transfer
- [ ] Approvals cleared on burn
- [ ] ApprovalForAll tracked correctly
- [ ] Approval events emitted

### Token ID Management

**ID Generation:**
- [ ] Token IDs unique
- [ ] No ID collisions
- [ ] Counter-based or hash-based generation
- [ ] Burned IDs not reused (unless intentional)

**ID Validation:**
- [ ] Token exists check before operations
- [ ] Zero token ID handling clear
- [ ] Max supply enforced (if applicable)

### Metadata

**Token URI:**
- [ ] tokenURI() implemented
- [ ] Returns valid URI
- [ ] Metadata format follows standard
- [ ] IPFS/Arweave for immutability (if applicable)
- [ ] Metadata update rules clear

**Metadata JSON schema:**
```json
{
  "name": "Token Name",
  "description": "Description",
  "image": "ipfs://...",
  "attributes": [...]
}
```

### Minting

**Mint Security:**
- [ ] Minting restricted
- [ ] Max supply enforced
- [ ] Zero address check
- [ ] Reentrancy protection (if payable)
- [ ] Events emitted

**Public Mint (if applicable):**
- [ ] Payment validation
- [ ] Mints per wallet limit
- [ ] Total supply limit
- [ ] Refund mechanism if overpaid
- [ ] Withdrawal protected

### Burning

- [ ] Only owner/approved can burn
- [ ] Burns decrease supply
- [ ] Ownership cleared
- [ ] Approvals cleared
- [ ] Events emitted
- [ ] Burned tokens not re-mintable (unless intentional)

### Enumeration

If implementing ERC721Enumerable:
- [ ] Gas costs acceptable
- [ ] tokenByIndex() works correctly
- [ ] tokenOfOwnerByIndex() works correctly
- [ ] totalSupply() accurate
- [ ] Transfers update enumeration
- [ ] Burns update enumeration

**Warning:** Enumeration adds significant gas overhead

### Royalties (EIP-2981)

If implementing royalties:
- [ ] royaltyInfo() implemented
- [ ] Royalty percentage reasonable (<10% typical)
- [ ] Royalty recipient valid
- [ ] Compatible with marketplaces

## ERC1155 (Multi-Token) Checklist

### Standard Compliance
- [ ] Implements all required ERC1155 functions
- [ ] Implements ERC1155MetadataURI
- [ ] Implements ERC165
- [ ] Batch operations work correctly
- [ ] Events emitted properly

**Required functions:**
- [ ] `balanceOf(address, uint256)` - Balance of token type
- [ ] `balanceOfBatch(address[], uint256[])` - Batch balance query
- [ ] `safeTransferFrom(address, address, uint256, uint256, bytes)` - Transfer
- [ ] `safeBatchTransferFrom(address, address, uint256[], uint256[], bytes)` - Batch transfer
- [ ] `setApprovalForAll(address, bool)` - Approve operator
- [ ] `isApprovedForAll(address, address)` - Check approval

### Safe Transfer

**Receiver Checks:**
- [ ] Checks receiver implements ERC1155Receiver
- [ ] Calls onERC1155Received/onERC1155BatchReceived
- [ ] Validates receiver return value
- [ ] Reverts if receiver rejects

### Batch Operations

**Batch Transfer:**
- [ ] Arrays same length
- [ ] All transfers atomic
- [ ] Reverts if any transfer fails
- [ ] Efficient gas usage
- [ ] Events emitted correctly

**Batch Safety:**
- [ ] No out-of-bounds access
- [ ] Handles empty arrays
- [ ] Handles large batches
- [ ] Gas limits considered

### Supply Tracking

If tracking supply per token ID:
- [ ] totalSupply(uint256 id) accurate
- [ ] Mint increases supply
- [ ] Burn decreases supply
- [ ] Batch operations update correctly

### Token ID System

**ID Organization:**
- [ ] Fungible token IDs clear
- [ ] Non-fungible token IDs clear
- [ ] ID ranges documented
- [ ] No ID collisions
- [ ] Max supply per ID (if applicable)

**Example:**
```solidity
// 0-999: Fungible tokens (currencies)
uint256 public constant GOLD = 0;
uint256 public constant SILVER = 1;

// 1000-9999: Semi-fungible (items)
uint256 public constant SWORD = 1000;

// 10000+: Unique NFTs
```

### Metadata

**URI Management:**
- [ ] uri(uint256 id) implemented
- [ ] {id} placeholder substitution correct
- [ ] Metadata schema followed
- [ ] Per-token URI option (if applicable)

## Common Token Vulnerabilities

### All Token Types

**Reentrancy:**
- [ ] No external calls before state updates
- [ ] ReentrancyGuard on payable functions
- [ ] Callbacks (receivers) can't reenter

**Access Control:**
- [ ] Mint function protected
- [ ] Burn authorization correct
- [ ] Admin functions restricted
- [ ] No unauthorized minting

**Integer Issues:**
- [ ] Using Solidity 0.8+
- [ ] No overflow in supply calculations
- [ ] No underflow in balance calculations

**Zero Address:**
- [ ] Zero address not valid recipient
- [ ] Zero address checks on mint
- [ ] Burns emit Transfer to zero address (ERC20/721)

### Integration Issues

**Protocol Compatibility:**
- [ ] Works with Uniswap/DEX
- [ ] Works with lending protocols
- [ ] Works with marketplaces
- [ ] No unexpected behavior with standard contracts

**Unexpected Behaviors:**
- [ ] No fee-on-transfer (unless documented)
- [ ] No rebasing (unless documented)
- [ ] No balance changes without transfer
- [ ] No blacklisting (unless documented)

## Testing Requirements

### Test Coverage

**ERC20:**
- [ ] Transfer to zero address reverts
- [ ] Transfer with insufficient balance reverts
- [ ] Approve and transferFrom works
- [ ] Approval race condition understood
- [ ] Total supply tracking correct

**ERC721:**
- [ ] Mint to zero address reverts
- [ ] Transfer updates ownership
- [ ] safeTransferFrom to non-receiver reverts
- [ ] Approvals work correctly
- [ ] Burn clears ownership and approvals

**ERC1155:**
- [ ] Batch operations with mismatched arrays revert
- [ ] Safe transfers to non-receivers revert
- [ ] Batch operations are atomic
- [ ] Supply tracking correct (if implemented)

### Fuzz Testing

- [ ] Random addresses
- [ ] Random amounts
- [ ] Random token IDs
- [ ] Edge cases (0, max uint256)
- [ ] Property-based tests

**Example properties:**
```solidity
// Invariant: Sum of balances equals total supply
function invariant_totalSupply() public {
    uint256 sum = 0;
    for (uint i = 0; i < holders.length; i++) {
        sum += token.balanceOf(holders[i]);
    }
    assertEq(sum, token.totalSupply());
}
```

## Quick Reference

| Token Type | Key Security Concerns |
|-----------|----------------------|
| ERC20 | Approval race, fee-on-transfer, return values |
| ERC721 | Safe transfer, unique IDs, receiver checks |
| ERC1155 | Batch atomicity, receiver checks, ID management |

---

**Remember:** Token standards have decades of battle-testing. Use OpenZeppelin implementations instead of custom code unless absolutely necessary.
