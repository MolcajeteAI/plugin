// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title GameItems
 * @dev Comprehensive ERC1155 multi-token contract for gaming items:
 * - Multiple token types in a single contract
 * - Burnable: Token holders can burn their items
 * - Supply tracking: Track total supply per token type
 * - Pausable: Emergency stop mechanism
 * - Ownable: Access control for administrative functions
 * - ReentrancyGuard: Protection against reentrancy attacks
 *
 * Token Types:
 * - 0: Gold (fungible currency)
 * - 1: Silver (fungible currency)
 * - 2: Gems (fungible currency)
 * - 10-19: Common Swords (semi-fungible items)
 * - 20-29: Rare Shields (semi-fungible items)
 * - 100+: Legendary Items (unique NFTs)
 */
contract GameItems is
    ERC1155,
    ERC1155Burnable,
    ERC1155Supply,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    /// @dev Token type constants for currencies
    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant GEMS = 2;

    /// @dev Token type ranges
    uint256 public constant COMMON_ITEMS_START = 10;
    uint256 public constant COMMON_ITEMS_END = 19;
    uint256 public constant RARE_ITEMS_START = 20;
    uint256 public constant RARE_ITEMS_END = 29;
    uint256 public constant LEGENDARY_ITEMS_START = 100;

    /// @dev Mapping from token ID to name
    mapping(uint256 => string) private _tokenNames;

    /// @dev Mapping from token ID to max supply (0 = unlimited)
    mapping(uint256 => uint256) private _maxSupply;

    /// @dev Mapping from token ID to mint price
    mapping(uint256 => uint256) private _mintPrices;

    /// @dev Emitted when a new token type is created
    event TokenTypeCreated(uint256 indexed id, string name, uint256 maxSupply);

    /// @dev Emitted when mint price is updated
    event MintPriceUpdated(uint256 indexed id, uint256 newPrice);

    /**
     * @dev Constructor initializes the contract with base URI
     */
    constructor()
        ERC1155("https://game.example/api/item/{id}.json")
        Ownable(msg.sender)
    {
        // Initialize default token types
        _createTokenType(GOLD, "Gold", 0); // Unlimited supply
        _createTokenType(SILVER, "Silver", 0); // Unlimited supply
        _createTokenType(GEMS, "Gems", 0); // Unlimited supply

        // Mint initial currencies to owner
        _mint(msg.sender, GOLD, 10000, "");
        _mint(msg.sender, SILVER, 10000, "");
        _mint(msg.sender, GEMS, 1000, "");
    }

    /**
     * @dev Creates a new token type
     * @param id Token ID
     * @param name Token name
     * @param maxSupply Maximum supply (0 for unlimited)
     *
     * Requirements:
     * - Only owner can create token types
     * - Token type must not already exist
     */
    function createTokenType(uint256 id, string memory name, uint256 maxSupply)
        public
        onlyOwner
    {
        _createTokenType(id, name, maxSupply);
    }

    /**
     * @dev Internal function to create token type
     */
    function _createTokenType(uint256 id, string memory name, uint256 maxSupply)
        internal
    {
        require(bytes(_tokenNames[id]).length == 0, "GameItems: type exists");
        _tokenNames[id] = name;
        _maxSupply[id] = maxSupply;
        emit TokenTypeCreated(id, name, maxSupply);
    }

    /**
     * @dev Sets the mint price for a token type
     * @param id Token ID
     * @param price Price in wei
     *
     * Requirements:
     * - Only owner can set prices
     */
    function setMintPrice(uint256 id, uint256 price) public onlyOwner {
        _mintPrices[id] = price;
        emit MintPriceUpdated(id, price);
    }

    /**
     * @dev Mints tokens to an address
     * @param to Address to receive tokens
     * @param id Token ID
     * @param amount Amount to mint
     *
     * Requirements:
     * - Only owner can mint
     * - Must not exceed max supply
     * - Contract must not be paused
     */
    function mint(address to, uint256 id, uint256 amount)
        public
        onlyOwner
        whenNotPaused
    {
        _checkSupply(id, amount);
        _mint(to, id, amount, "");
    }

    /**
     * @dev Public mint function with payment
     * @param id Token ID
     * @param amount Amount to mint
     *
     * Requirements:
     * - Must send correct payment
     * - Must not exceed max supply
     * - Contract must not be paused
     */
    function publicMint(uint256 id, uint256 amount)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 price = _mintPrices[id];
        require(price > 0, "GameItems: not available for public mint");
        require(msg.value >= price * amount, "GameItems: insufficient payment");

        _checkSupply(id, amount);
        _mint(msg.sender, id, amount, "");
    }

    /**
     * @dev Batch mints multiple token types
     * @param to Address to receive tokens
     * @param ids Array of token IDs
     * @param amounts Array of amounts
     *
     * Requirements:
     * - Only owner can batch mint
     * - Arrays must have same length
     * - Must not exceed max supply for any token
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public
        onlyOwner
        whenNotPaused
    {
        require(ids.length == amounts.length, "GameItems: length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            _checkSupply(ids[i], amounts[i]);
        }

        _mintBatch(to, ids, amounts, "");
    }

    /**
     * @dev Checks if minting would exceed max supply
     */
    function _checkSupply(uint256 id, uint256 amount) internal view {
        uint256 maxSupply = _maxSupply[id];
        if (maxSupply > 0) {
            require(
                totalSupply(id) + amount <= maxSupply,
                "GameItems: exceeds max supply"
            );
        }
    }

    /**
     * @dev Pauses all token operations
     *
     * Requirements:
     * - Only owner can pause
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token operations
     *
     * Requirements:
     * - Only owner can unpause
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates the base URI for all tokens
     * @param newuri New base URI
     *
     * Requirements:
     * - Only owner can update URI
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev Withdraws contract balance
     *
     * Requirements:
     * - Only owner can withdraw
     */
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "GameItems: no balance");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "GameItems: withdrawal failed");
    }

    /**
     * @dev Returns the name of a token type
     */
    function name(uint256 id) public view returns (string memory) {
        return _tokenNames[id];
    }

    /**
     * @dev Returns the max supply of a token type (0 = unlimited)
     */
    function maxSupply(uint256 id) public view returns (uint256) {
        return _maxSupply[id];
    }

    /**
     * @dev Returns the mint price of a token type
     */
    function mintPrice(uint256 id) public view returns (uint256) {
        return _mintPrices[id];
    }

    /**
     * @dev Returns the remaining supply of a token type
     */
    function remainingSupply(uint256 id) public view returns (uint256) {
        uint256 maxSupply_ = _maxSupply[id];
        if (maxSupply_ == 0) {
            return type(uint256).max; // Unlimited
        }
        return maxSupply_ - totalSupply(id);
    }

    /**
     * @dev Returns all token IDs owned by an address
     * @param account Address to query
     * @param startId Starting token ID to check
     * @param endId Ending token ID to check
     */
    function tokensOfOwner(address account, uint256 startId, uint256 endId)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        require(endId >= startId, "GameItems: invalid range");

        uint256[] memory tempIds = new uint256[](endId - startId + 1);
        uint256[] memory tempBalances = new uint256[](endId - startId + 1);
        uint256 count = 0;

        for (uint256 i = startId; i <= endId; i++) {
            uint256 balance = balanceOf(account, i);
            if (balance > 0) {
                tempIds[count] = i;
                tempBalances[count] = balance;
                count++;
            }
        }

        // Resize arrays to actual count
        uint256[] memory ids = new uint256[](count);
        uint256[] memory balances = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = tempIds[i];
            balances[i] = tempBalances[i];
        }

        return (ids, balances);
    }

    // Override required functions

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
        whenNotPaused
    {
        super._update(from, to, ids, values);
    }
}
