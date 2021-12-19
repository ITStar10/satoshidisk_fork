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
    mapping(uint256 => TokenInfo) private tokenInfoList;
 
    /** Struct
     */
    struct TokenInfo {
        uint256 tokenId;
        string tokenURI;
        uint256 price;
        string description;

        address mintedBy;
        address previousOwner;
    }
    

    /**
     * @dev Emitted when new Token minted.
     */
    event MintNewToken(
        address minter, 
        string tokenURI,
        uint256 price,
        string description
    );
    
    /**
     * @dev Emitted when price changed by owner.
     */
    event PriceChanged(
        address owner,
        uint256 tokenId,
        uint256 oldPrice,
        uint256 newPrice
    );

    /**
     * @dev Emitted when token bought to new user.
     */
    event BuyToken(
        address buyer,
        uint256 tokenId
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
        string memory description
    ) external nonReentrant returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(recipient, newItemId);

        TokenInfo memory newItemInfo = TokenInfo(
            newItemId,
            tokenURI,
            price,
            description,
            _msgSender(),
            address(0)
        );

        tokenInfoList[newItemId] = newItemInfo;

        

        emit MintNewToken(_msgSender(), tokenURI, price, description);
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
    function tokenPrice(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "SatoToken: URI query for nonexistent token");

        return tokenInfoList[tokenId].price;
    }


    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    /**
     * Buy token 
     */
    function buyNFT(uint256 tokenId) public payable nonReentrant {
        // check if the function caller is not an zero account address
        require(_msgSender() != address(0), "null address");
        // check if the token id of the token being bought exists or not
        require(_exists(tokenId), "non-existent token");

        address tokenOwner = ownerOf(tokenId);
        // token's owner should not be an zero address account
        require(tokenOwner != address(0), "owner is null");
        // the one who wants to buy the token should not be the token's owner
        require(tokenOwner != _msgSender(), "buyer should not be owner");

        TokenInfo memory tokenItem = tokenInfoList[tokenId];

        // price sent in to buy should be equal to or more than the token's price
        require(msg.value >= tokenItem.price, "insufficient money to buy");

        console.log("buyNFT() : ", address(this).balance);

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(tokenOwner, _msgSender(), tokenId);

        // send token's worth of ethers to the owner
        uint256 feeValue = msg.value * taxFee /  100;
        uint256 soldValue = msg.value - feeValue;
        // payable(tokenOwner).transfer(soldValue);
        payable(tokenOwner).send(soldValue);

        console.log("buyNFT() -- 1 : ", address(this).balance);


        // update the token's previous owner
        tokenItem.previousOwner = tokenOwner;
        // set and update that token in the mapping
        tokenInfoList[tokenId] = tokenItem;

        emit BuyToken(_msgSender(), tokenId);
    }

    /**
     * Set token price
     */
    function setTokenPrice(uint256 tokenId, uint256 newPrice) public nonReentrant {
        // require caller of the function is not an empty address
        require(_msgSender() != address(0), "null address");
        // require that token should exist
        require(_exists(tokenId), "token must exist");

        // get the token's owner
        address tokenOwner = ownerOf(tokenId);
        // check that token's owner should be equal to the caller of the function
        require(tokenOwner == _msgSender(), "Only owner can set the price");

        TokenInfo memory tokenItem = tokenInfoList[tokenId];
        // update token price
        uint256 oldPrice = tokenItem.price;
        tokenItem.price = newPrice;
        
        tokenInfoList[tokenId] = tokenItem;

        emit PriceChanged(tokenOwner, tokenId, oldPrice, newPrice);
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