# Token Standards

Standard interfaces for fungible tokens (ERC20), non-fungible tokens (ERC721), and multi-token contracts (ERC1155).

## ERC20 - Fungible Tokens

**Use case:** Currencies, utility tokens, governance tokens (USDC, DAI, UNI)

### Basic ERC20

```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    constructor() ERC20("MyToken", "MTK") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```

### ERC20 with Supply Cap

```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract CappedToken is ERC20Capped {
    constructor()
        ERC20("MyToken", "MTK")
        ERC20Capped(1000000 * 10 ** decimals())
    {
        _mint(msg.sender, 500000 * 10 ** decimals());
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Capped)
    {
        super._update(from, to, value);
    }
}
```

### Key Functions

- `totalSupply()` - Total token supply
- `balanceOf(address)` - Balance of an account
- `transfer(address, uint256)` - Transfer tokens
- `approve(address, uint256)` - Approve spending
- `transferFrom(address, address, uint256)` - Transfer on behalf
- `allowance(address, address)` - Check approved amount

## ERC721 - Non-Fungible Tokens (NFTs)

**Use case:** Unique digital assets, collectibles, art, real estate

### Basic ERC721

```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    function mint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
}
```

### ERC721 with URI Storage

```solidity
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    function mint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
}
```

### ERC721 with Enumeration

```solidity
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MyNFT is ERC721Enumerable, Ownable {
    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    function mint(address to) public onlyOwner {
        uint256 tokenId = totalSupply();
        _safeMint(to, tokenId);
    }

    // Enumerate tokens
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(owner);
        uint256[] memory tokens = new uint256[](balance);

        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }

        return tokens;
    }
}
```

### Key Functions

- `balanceOf(address)` - Number of tokens owned
- `ownerOf(uint256)` - Owner of a specific token
- `safeTransferFrom(address, address, uint256)` - Safe transfer
- `transferFrom(address, address, uint256)` - Transfer token
- `approve(address, uint256)` - Approve transfer
- `setApprovalForAll(address, bool)` - Approve all tokens
- `getApproved(uint256)` - Get approved address
- `isApprovedForAll(address, address)` - Check operator approval

## ERC1155 - Multi-Token Standard

**Use case:** Gaming items, multiple token types in one contract

### Basic ERC1155

```solidity
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameItems is ERC1155, Ownable {
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant SWORD = 2;
    uint256 public constant SHIELD = 3;

    constructor() ERC1155("https://game.example/api/item/{id}.json") Ownable(msg.sender) {}

    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }
}
```

### ERC1155 with Supply Tracking

```solidity
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract GameItems is ERC1155Supply, Ownable {
    constructor() ERC1155("https://game.example/api/item/{id}.json") Ownable(msg.sender) {}

    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function totalSupply(uint256 id) public view override returns (uint256) {
        return super.totalSupply(id);
    }

    function exists(uint256 id) public view override returns (bool) {
        return super.exists(id);
    }
}
```

### Key Functions

- `balanceOf(address, uint256)` - Balance of specific token type
- `balanceOfBatch(address[], uint256[])` - Batch balance query
- `safeTransferFrom(address, address, uint256, uint256, bytes)` - Transfer tokens
- `safeBatchTransferFrom(address, address, uint256[], uint256[], bytes)` - Batch transfer
- `setApprovalForAll(address, bool)` - Approve operator
- `isApprovedForAll(address, address)` - Check approval

## Token Comparison

| Feature | ERC20 | ERC721 | ERC1155 |
|---------|-------|--------|---------|
| Fungible | ✅ Yes | ❌ No | ✅ Both |
| Batch operations | ❌ No | ❌ No | ✅ Yes |
| Gas efficiency | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| Metadata | ❌ No | ✅ Yes | ✅ Yes |
| Use case | Currencies | NFTs | Gaming |

## Common Extensions

### ERC20 Extensions

**ERC20Burnable** - Allow token burning
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BurnableToken is ERC20Burnable {
    // Adds burn() and burnFrom() functions
}
```

**ERC20Permit** - Gasless approvals via signatures
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract PermitToken is ERC20Permit {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}
    // Adds permit() function for signature-based approvals
}
```

**ERC20Snapshot** - Historical balance queries
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract SnapshotToken is ERC20Snapshot, Ownable {
    function snapshot() public onlyOwner returns (uint256) {
        return _snapshot();
    }
    // Adds balanceOfAt() and totalSupplyAt()
}
```

**ERC20Votes** - Voting power tracking
```solidity
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract GovernanceToken is ERC20Votes {
    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {}
    // Adds delegate(), getPastVotes(), getPastTotalSupply()
}
```

### ERC721 Extensions

**ERC721Burnable** - Allow NFT burning
```solidity
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract BurnableNFT is ERC721Burnable {
    // Adds burn() function
}
```

**ERC721Royalty** - Royalty support (EIP-2981)
```solidity
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract RoyaltyNFT is ERC721Royalty {
    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
        _setTokenRoyalty(tokenId, to, 500); // 5% royalty
    }
}
```

### ERC1155 Extensions

**ERC1155Burnable** - Allow token burning
```solidity
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract BurnableGameItems is ERC1155Burnable {
    // Adds burn() and burnBatch() functions
}
```

**ERC1155URIStorage** - Per-token URI storage
```solidity
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract StorageGameItems is ERC1155URIStorage {
    function mint(address to, uint256 id, string memory tokenURI) public {
        _mint(to, id, 1, "");
        _setURI(id, tokenURI);
    }
}
```

## Best Practices

1. **Use OpenZeppelin** - Battle-tested implementations
2. **Follow the standard** - Don't deviate from ERC interfaces
3. **Safe transfers** - Use `safeTransferFrom` for ERC721/1155
4. **Reentrancy protection** - Add `nonReentrant` to public functions
5. **Access control** - Restrict minting and administrative functions
6. **Metadata standards** - Follow JSON schema for token metadata
7. **Test thoroughly** - Test all transfer scenarios and edge cases
8. **Consider gas costs** - Batch operations for multiple transfers
9. **Emit events** - Log all important state changes

## Metadata Standards

### ERC721 Metadata JSON Schema

```json
{
  "name": "Item Name",
  "description": "Description of the item",
  "image": "ipfs://QmHash/image.png",
  "attributes": [
    {
      "trait_type": "Rarity",
      "value": "Legendary"
    },
    {
      "trait_type": "Power",
      "value": 100,
      "max_value": 100
    }
  ]
}
```

### ERC1155 Metadata JSON Schema

```json
{
  "name": "Item Name",
  "description": "Description of the item",
  "image": "ipfs://QmHash/image.png",
  "properties": {
    "simple_property": "value",
    "rich_property": {
      "name": "Name",
      "value": "Value"
    }
  }
}
```

## Security Considerations

1. **Integer overflow** - Use Solidity 0.8+ (automatic overflow checks)
2. **Reentrancy** - Protect transfer functions
3. **Front-running** - Consider commit-reveal for minting
4. **Gas limits** - Avoid unbounded loops (especially in ERC721Enumerable)
5. **Approval exploits** - Be careful with infinite approvals
6. **Token ID collisions** - Use counters or unique generation

## Anti-Patterns to Avoid

1. **Custom implementations** - Use OpenZeppelin instead
2. **Skipping safe transfers** - Always use `safeMint` and `safeTransferFrom`
3. **No access control on mint** - Restrict who can mint
4. **Ignoring standards** - Follow ERCs exactly
5. **No URI validation** - Validate metadata URIs
6. **Mutable token IDs** - Token IDs should never change

---

**Remember:** Use OpenZeppelin's implementations. They're audited, gas-optimized, and follow best practices.
