// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title MyNFT
 * @dev Comprehensive ERC721 NFT with common features:
 * - URI Storage: Store metadata URI for each token
 * - Burnable: Token owners can burn their NFTs
 * - Royalty: EIP-2981 royalty support for marketplace compatibility
 * - Pausable: Emergency stop mechanism for minting
 * - Ownable: Access control for administrative functions
 * - ReentrancyGuard: Protection against reentrancy attacks
 */
contract MyNFT is
    ERC721,
    ERC721URIStorage,
    ERC721Burnable,
    ERC721Royalty,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    /// @dev Counter for token IDs
    uint256 private _nextTokenId;

    /// @dev Maximum supply of NFTs
    uint256 public constant MAX_SUPPLY = 10_000;

    /// @dev Minting price in wei
    uint256 public mintPrice = 0.01 ether;

    /// @dev Base URI for computing tokenURI
    string private _baseTokenURI;

    /// @dev Emitted when mint price is updated
    event MintPriceUpdated(uint256 oldPrice, uint256 newPrice);

    /// @dev Emitted when base URI is updated
    event BaseURIUpdated(string newBaseURI);

    /**
     * @dev Constructor initializes the NFT collection
     */
    constructor()
        ERC721("MyNFT", "MNFT")
        Ownable(msg.sender)
    {
        // Set default royalty to 5% for the owner
        _setDefaultRoyalty(msg.sender, 500); // 500 basis points = 5%
    }

    /**
     * @dev Sets the base URI for all token URIs
     * @param baseURI The new base URI
     *
     * Requirements:
     * - Only owner can set base URI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    /**
     * @dev Returns the base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Updates the mint price
     * @param newPrice New price in wei
     *
     * Requirements:
     * - Only owner can update price
     */
    function setMintPrice(uint256 newPrice) public onlyOwner {
        uint256 oldPrice = mintPrice;
        mintPrice = newPrice;
        emit MintPriceUpdated(oldPrice, newPrice);
    }

    /**
     * @dev Public mint function
     * @param to Address to receive the NFT
     *
     * Requirements:
     * - Contract must not be paused
     * - Must send correct mint price
     * - Max supply not exceeded
     */
    function mint(address to)
        public
        payable
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        require(msg.value >= mintPrice, "MyNFT: insufficient payment");
        require(_nextTokenId < MAX_SUPPLY, "MyNFT: max supply reached");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        return tokenId;
    }

    /**
     * @dev Owner mint function with custom URI
     * @param to Address to receive the NFT
     * @param uri Token URI for metadata
     *
     * Requirements:
     * - Only owner can mint with custom URI
     * - Max supply not exceeded
     */
    function mintWithURI(address to, string memory uri)
        public
        onlyOwner
        returns (uint256)
    {
        require(_nextTokenId < MAX_SUPPLY, "MyNFT: max supply reached");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
    }

    /**
     * @dev Batch mint function for owner
     * @param to Address to receive the NFTs
     * @param quantity Number of NFTs to mint
     *
     * Requirements:
     * - Only owner can batch mint
     * - Max supply not exceeded
     */
    function batchMint(address to, uint256 quantity)
        public
        onlyOwner
        returns (uint256[] memory)
    {
        require(_nextTokenId + quantity <= MAX_SUPPLY, "MyNFT: exceeds max supply");

        uint256[] memory tokenIds = new uint256[](quantity);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId++;
            _safeMint(to, tokenId);
            tokenIds[i] = tokenId;
        }

        return tokenIds;
    }

    /**
     * @dev Pauses minting
     *
     * Requirements:
     * - Only owner can pause
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses minting
     *
     * Requirements:
     * - Only owner can unpause
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraw contract balance
     *
     * Requirements:
     * - Only owner can withdraw
     */
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "MyNFT: no balance to withdraw");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "MyNFT: withdrawal failed");
    }

    /**
     * @dev Returns the total number of tokens minted
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev Returns the remaining tokens that can be minted
     */
    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - _nextTokenId;
    }

    // Override required functions

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
