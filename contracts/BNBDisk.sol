//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract BNBDisk is Ownable, ReentrancyGuard {
    /** State Variables
     */
    // Total number of SatoTokens
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private taxFee;

    // map token id to struct
    mapping (uint256 => TokenInfo) private tokenList;
    mapping (uint256 => mapping(address => bool)) private isTokenBought;

    /** Struct
     */
    struct TokenInfo {
        // uint256 tokenId;
        string tokenURI;
        // uint256 tokenTotalCount;
        // uint256 startPrice;
        uint256 tokenCount;
        bool    isUnlimitedSale;
        uint256 tokenPrice;
        address tokenOwner;
    }

    modifier tokenOwned(uint256 _tokenId, address _tokenOwner) {
        TokenInfo storage tokenInfo = tokenList[_tokenId];
        // console.log("Input : ", _tokenId, _tokenOwner);
        // console.log("TokenInfo : ", tokenInfo.tokenOwner, tokenInfo.isUnlimitedSale, tokenInfo.tokenCount);
        require(
            tokenInfo.tokenOwner == _tokenOwner && (tokenInfo.isUnlimitedSale || tokenInfo.tokenCount > 0),
            "No token"
        );
        _;
    }

    /**
     * @dev Emitted when new Token minted.
     */
    event MintNewToken(
        uint256 indexed tokenId,
        address indexed minter, 
        string  tokenURI,
        uint256 tokenCount,
        uint256 tokenPrice
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

    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return tokenList[_tokenId].tokenOwner != address(0);
    }

    // Set TaxFee
    function setTaxFee(uint256 _newFee) public onlyOwner {
        require(_newFee <= 20, "Tax can not be over 20%");
        taxFee = _newFee;
    }

    function getTaxFee() external view returns(uint256) {
        return taxFee;
    }

    // Mint a new Token
    function mintNFT(
        address _recipient,
        string memory _tokenURI, 
        uint256 _price,
        uint256 _count
    ) external nonReentrant returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        require(_recipient != address(0), "Mint to the zero address");
        bool _isUnlimitedSale = _count == 0;
        TokenInfo memory newItemInfo = TokenInfo(
            _tokenURI,
            _count,
            _isUnlimitedSale,
            _price,
            _recipient // or _msgSender(),
        );

        tokenList[newItemId] = newItemInfo;    

        emit MintNewToken(newItemId, _msgSender(), _tokenURI, _count, _price);
        return newItemId;
    }

    // Get total number of tokens minted
    function getNumberOfTokensMinted() external view returns (uint256) {
        return _tokenIds.current();   
    }

    // Get URI of tokenId
    function tokenURI(uint256 _tokenId) public view  returns (string memory) {
        require(_exists(_tokenId), "BNBDisk: URI query for nonexistent token");
        return tokenList[_tokenId].tokenURI;
    }

    function tokenPrice(
        uint256 _tokenId, 
        address _tokenOwner
    ) public view tokenOwned(_tokenId, _tokenOwner) returns (uint256) {
        require(_exists(_tokenId), "BNBDisk: Invalid token ID");
        return tokenList[_tokenId].tokenPrice;
    }

    function tokenCount(
        uint256 _tokenId,
        address _tokenOwner
    ) public view tokenOwned(_tokenId, _tokenOwner) returns (uint256 , bool) {
        TokenInfo storage tokenInfo = tokenList[_tokenId];
        return (tokenInfo.tokenCount, tokenInfo.isUnlimitedSale);
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "BNBDisk: Invalid token ID");
        return tokenList[_tokenId].tokenOwner;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    /**
     * Check purchased status
     */
    function isPurchased(
        uint256 _tokenId,
        address _address
    ) external view returns (bool) {
        return isTokenBought[_tokenId][_address];
    }

    /**
     * Buy token 
     */
    function buyNFT(
        uint256 _tokenId,
        address _owner
    ) public payable nonReentrant tokenOwned(_tokenId, _owner) {
        require(_msgSender() != address(0), "null address");
        require(_exists(_tokenId), "non-existent token");

        require(_owner != _msgSender(), "buyer should not be owner");
        require(!isTokenBought[_tokenId][_msgSender()], "Already purchased");

        TokenInfo memory tokenInfo = tokenList[_tokenId];
        
        require(msg.value >= tokenInfo.tokenPrice, "insufficient money");

        if (!tokenInfo.isUnlimitedSale) {
            
            tokenInfo.tokenCount = tokenInfo.tokenCount - 1;
        }

        // send token's worth of ethers to the owner
        
        uint256 feeValue = msg.value * taxFee /  100;
        uint256 soldValue = msg.value - feeValue;
        (bool sent, ) = payable(_owner).call{value: soldValue}("");
        require(sent, "Failed to send payment");

        tokenList[_tokenId] = tokenInfo;
        isTokenBought[_tokenId][_msgSender()] = true;
        emit BuyToken(_tokenId, _owner, _msgSender(), tokenInfo.tokenPrice);
    }

    /**
     * Set token price
     */
    function setTokenPrice(
        uint256 _tokenId,
        uint256 _newPrice
    ) public tokenOwned(_tokenId, _msgSender()) nonReentrant {
        require(_msgSender() != address(0), "null address");
        require(_exists(_tokenId), "token not exist");

        uint256 oldPrice = tokenList[_tokenId].tokenPrice;
        tokenList[_tokenId].tokenPrice = _newPrice;
        
        emit PriceChanged(_tokenId, _msgSender(), oldPrice, _newPrice);
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (msg.sender).call{value:balance}("");
        require(success, "Transfer failed");
    }
}
