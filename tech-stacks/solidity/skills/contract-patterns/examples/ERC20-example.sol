// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title MyToken
 * @dev Comprehensive ERC20 token with common features:
 * - Burnable: Token holders can burn their tokens
 * - Permit: Gasless approvals via EIP-2612
 * - Pausable: Emergency stop mechanism
 * - Ownable: Access control for administrative functions
 * - Capped: Maximum supply of 1,000,000 tokens
 */
contract MyToken is ERC20, ERC20Burnable, ERC20Permit, Ownable, Pausable {
    /// @dev Maximum token supply cap
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    /// @dev Current total minted tokens (including burned)
    uint256 public totalMinted;

    /**
     * @dev Constructor that mints initial supply to the deployer
     */
    constructor()
        ERC20("MyToken", "MTK")
        ERC20Permit("MyToken")
        Ownable(msg.sender)
    {
        // Mint initial supply of 500,000 tokens to deployer
        _mint(msg.sender, 500_000 * 10 ** decimals());
        totalMinted = 500_000 * 10 ** decimals();
    }

    /**
     * @dev Mints new tokens to specified address
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint (in wei)
     *
     * Requirements:
     * - Only owner can mint
     * - Cannot exceed max supply
     * - Contract must not be paused
     */
    function mint(address to, uint256 amount) public onlyOwner whenNotPaused {
        require(totalMinted + amount <= MAX_SUPPLY, "MyToken: cap exceeded");
        _mint(to, amount);
        totalMinted += amount;
    }

    /**
     * @dev Pauses all token transfers
     *
     * Requirements:
     * - Only owner can pause
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers
     *
     * Requirements:
     * - Only owner can unpause
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Hook that is called before any transfer of tokens
     * Implements pausable functionality
     */
    function _update(address from, address to, uint256 value)
        internal
        override
        whenNotPaused
    {
        super._update(from, to, value);
    }

    /**
     * @dev Returns the remaining tokens that can be minted
     */
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - totalMinted;
    }
}
