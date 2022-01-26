// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./helpers/Context.sol";
import "./helpers/Ownable.sol";
import "./helpers/IERC20.sol";
import "./helpers/SafeMath.sol";
import "./helpers/SafeERC20.sol";
import "./helpers/ReentrancyGuard.sol";
import "./helpers/Strings.sol";


contract Payment is Context, Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Strings for string;

    mapping(uint256 => address) public supportedTokens;
    uint256 tokenCount = 1;
    mapping(address => uint256) public paymentTokensIndex;

    address payable public wallet;

    struct Product{
        string asin;
        uint256 price;
        uint256 quantity;
    }

    struct OrderDetail{
        string orderID;
        string paymentID;
        address tokenAddress;
        uint tokenIndex;
        uint256 totalPrice;
        uint256 totalQty;
        uint256 numOfProducts;
        address buyer;
    }

    mapping(string => Product[]) orderProducts;
    mapping(address => mapping(string => OrderDetail)) transactions;
    mapping(address => uint256) tokenAmounts;
    event TransactionMade(string indexed orderID, string indexed paymentID, address indexed buyer);
    event NewTokenAdded(address indexed tokenAddress, uint256 indexed tokenIndex);
    event NewWalletSet(address indexed walletAddress);


    constructor(address payable _wallet) {
        wallet = _wallet;
    }


    function makePayment(
        string memory orderId,
        uint256 tokenIndex,
        uint256 totalPrice,
        uint256 totalQty,
        Product[] memory products
        ) public 
        {
        require(supportedTokens[tokenIndex] != address(0), "makePayment: Invalid token index");
        IERC20 paymentToken = IERC20(supportedTokens[tokenIndex]); // Uncomment this
        
        // Check allowance and transfer token
        uint256 allowance = paymentToken.allowance(_msgSender(), address(this)); // Uncomment this
        require(allowance >= totalPrice, "makePayment: Contract not approved to make payment"); // Uncomment this
        
        paymentToken.safeTransferFrom(_msgSender(), wallet, totalPrice); // Uncomment this
        

        // Record the transaction details
        OrderDetail storage detail = transactions[_msgSender()][orderId];
        detail.orderID = orderId;
        detail.paymentID = Strings.toString(uint256(keccak256(abi.encode(orderId, block.timestamp, _msgSender()))));
        detail.tokenAddress = supportedTokens[tokenIndex];
        detail.tokenIndex = tokenIndex;
        detail.totalPrice = totalPrice;
        detail.totalQty = totalQty;
        detail.numOfProducts = products.length;
        detail.buyer = _msgSender();
        
        for(uint i = 0; i < products.length; i++){
            // orderProducts[orderId][i] = products[i];
            orderProducts[orderId].push(products[i]);
        }

        emit TransactionMade(orderId, detail.paymentID, _msgSender());

    }


    // Setter functions
    function setWallet(address payable newWallet) public onlyOwner{
        wallet = newWallet;
        emit NewWalletSet(newWallet);
    }
    function addPaymentToken(address newTokenAddress) public onlyOwner{
        supportedTokens[tokenCount] = newTokenAddress;
        paymentTokensIndex[newTokenAddress] = tokenCount;
        tokenCount = tokenCount.add(1);

        emit NewTokenAdded(newTokenAddress, tokenCount.sub(1));
    }

    
    // Getter functions
    
    function getTokenIndex(address tokenAddress) public view returns(uint256){
        require(paymentTokensIndex[tokenAddress] != 0, "getTokenIndex: Not a supported payment token");
        return paymentTokensIndex[tokenAddress];
    }

    function getTransactionDetails(address buyer, string memory orderId) public view returns(OrderDetail memory){
        return transactions[buyer][orderId];
    }


}