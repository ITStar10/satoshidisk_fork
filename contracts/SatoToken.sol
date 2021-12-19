//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";


contract SatoToken is ERC721, ReentrancyGuard, Ownable {
    /** State Variables
     */
    // Total number of SatoTokens
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 taxFee;

    // map token id to struct
    mapping (uint256 => TokenInfo) private tokenInfoList;
    mapping (uint256 => mapping(address => TokenPriceInfo)) private tokenOwners;
 
    /** Struct
     */
    struct TokenInfo {
        uint256 tokenId;
        string tokenURI;
        uint256 tokenTotalCount;
        uint256 startPrice;
        address mintedBy;
    }

    struct TokenPriceInfo {
        uint256 tokenCount;
        uint256 tokenPrice;
    }

    modifier tokenOwned(uint256 tokenId, address tokenOwner) {
        require(tokenOwners[tokenId][tokenOwner].tokenCount > 0, "No token");
        _;
    }

    modifier enoughToken(uint256 tokenId, address tokenOwner, uint256 count) {
        require(tokenOwners[tokenId][tokenOwner].tokenCount >= count, "Not enough token");
        _;
    }

    /**
     * @dev Emitted when new Token minted.
     */
    event MintNewToken(
        uint256 indexed tokenId,
        address indexed minter, 
        string tokenURI,
        uint256 tokenCount,
        uint256 startPrice
    );
    
    /**
     * @dev Emitted when price changed by owner.
     */
    event PriceChanged(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 oldPrice,
        uint256 newPrice
    );

    /**
     * @dev Emitted when token bought to new user.
     */
    event BuyToken(
        uint256 indexed tokenId,
        address indexed from,
        address indexed buyer,
        uint256 tokenPrice
    );


    /** Functions
     */

    constructor() ERC721("SatoNFT", "NFT"){}

    // Set TaxFee
    function setTaxFee(uint256 newFee) public onlyOwner {
        require(newFee <= 20, "Tax can not be over 20%");
        taxFee = newFee;
    }

    // Mint a new Token
    function mintNFT(
        address recipient,
        string memory tokenURI, 
        uint256 price,
        uint256 count
    ) external nonReentrant returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(recipient, newItemId);

        TokenInfo memory newItemInfo = TokenInfo(
            newItemId,
            tokenURI,
            count,
            price,
            recipient // or _msgSender(),
        );

        TokenPriceInfo memory priceInfo = TokenPriceInfo(
            count,
            price
        );

        tokenInfoList[newItemId] = newItemInfo;
        tokenOwners[newItemId][recipient] = priceInfo;
      

        emit MintNewToken(newItemId, _msgSender(), tokenURI, count, price);
        return newItemId;
    }

    // Get total number of tokens minted
    function getNumberOfTokensMinted() external view returns (uint256) {
        return _tokenIds.current();   
    }

    // Get URI of tokenId
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "SatoToken: URI query for nonexistent token");
        
        return tokenInfoList[tokenId].tokenURI;
    }

    /**
     * Get token price for {tokenId}
     */
    function tokenPrice(
        uint256 tokenId, 
        address tokenOwner
    ) public view tokenOwned(tokenId, tokenOwner) returns (uint256) {
        require(_exists(tokenId), "SatoToken: Invalid token ID");
        return tokenOwners[tokenId][tokenOwner].tokenPrice;
    }

    function tokenCount(
        uint256 tokenId,
        address tokenOwner
    ) public view returns (uint256) {
        return tokenOwners[tokenId][tokenOwner].tokenCount;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {}

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    /**
     * return 
     */

    /**
     * Buy token 
     */
    function buyNFT(
        uint256 tokenId,
        address owner,
        uint256 count
    ) public payable nonReentrant enoughToken(tokenId, owner, count) {
        require(_msgSender() != address(0), "null address");
        require(_exists(tokenId), "non-existent token");

        require(owner != _msgSender(), "buyer should not be owner");
        require(count > 0, "buy count should be over 0");
        
        uint256 tokenPrice = tokenOwners[tokenId][owner].tokenPrice;
        uint256 totalPrice = tokenPrice * count;
        require(msg.value >= totalPrice, "insufficient money");

        TokenPriceInfo memory ownerInfo = tokenOwners[tokenId][owner];
        ownerInfo.tokenCount = ownerInfo.tokenCount - count;

        TokenPriceInfo memory buyerInfo = tokenOwners[tokenId][_msgSender()];
        buyerInfo.tokenCount = buyerInfo.tokenCount + count;
        if (buyerInfo.tokenCount == 0) {
            buyerInfo.tokenPrice = tokenPrice;
        }

        tokenOwners[tokenId][owner] = ownerInfo;
        tokenOwners[tokenId][_msgSender()] = buyerInfo;

        // send token's worth of ethers to the owner
        uint256 feeValue = msg.value * taxFee /  100;
        uint256 soldValue = msg.value - feeValue;
        (bool sent, bytes memory data) = payable(owner).call{value: soldValue}("");
        require(sent, "Failed to send payment");
        // payable(owner).send(soldValue);

        console.log("buyNFT() -- 1 : ", address(this).balance);

        emit BuyToken(tokenId, owner, _msgSender(), tokenPrice);
    }

    /**
     * Set token price
     */
    function setTokenPrice(
        uint256 tokenId,
         uint256 newPrice
    ) public tokenOwned(tokenId, _msgSender()) nonReentrant {
        require(_msgSender() != address(0), "null address");
        require(_exists(tokenId), "token not exist");

        address tokenOwner = _msgSender();

        TokenPriceInfo memory priceInfo = tokenOwners[tokenId][tokenOwner];
        // update token price
        uint256 oldPrice = priceInfo.tokenPrice;
        priceInfo.tokenPrice = newPrice;
        tokenOwners[tokenId][tokenOwner] = priceInfo;
        
        emit PriceChanged(tokenId, tokenOwner, oldPrice, newPrice);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {}

}