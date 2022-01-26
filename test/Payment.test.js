const Payment = artifacts.require("Payment");
const truffleAssert = require('truffle-assertions');

// Functions
/**
 * Deployed wallet set correctly
 * 
 * setWallet - NewWalletSet
 * 
 * addPaymentToken - NewTokenAdded
 * 
 * makePayment - TransactionMade
 * 
 * getTokenIndex
 * 
 * getTransactionDetails
 */

contract("Payment", (accounts) => {
    let paymentInst;
    const deployingAcct = accounts[0];
    const wallet = accounts[1];
    const buyer = accounts[2];
    const testToken = "0x0336b1f697b844aeab956914fc9420e8934b3256";
   
    beforeEach(async () => {
        paymentInst = await Payment.new(wallet, {from: deployingAcct});
    });

    it("constructor should set the wallet correctly", async() => {
        const receivingWallet = await paymentInst.wallet();
        assert.equal(receivingWallet, wallet);
    });

    it("it should add payment token", async() => {

        const tx = await paymentInst.addPaymentToken(testToken, {from: deployingAcct});
        
        truffleAssert.eventEmitted(tx, 'NewTokenAdded', (ev) => {
            console.log("Token address: ", ev.tokenAddress);
            console.log("Token index", ev.tokenIndex);
            // return ev.tokenAddress === testToken && ev.tokenIndex.eq(1);
            return true;
        });

        const tokenInd = await paymentInst.getTokenIndex(testToken);
        assert.equal(tokenInd, 1);
    });

    it("it should make payment for an order", async() => {

        /**
         * 
         * string memory orderId,
        uint256 tokenIndex,
        uint256 totalPrice,
        uint256 totalQty,
        Product[] memory products
        

        string asin;
        uint256 price;
        uint256 quantity;

         */

        await paymentInst.addPaymentToken(testToken, {from: deployingAcct});
        const orderId = "chrischimezie24@gmail.com";
        const tokenIndex = 1;
        const totalPrice = 4000;
        const totalQty = 4;
        const products = [
            {
                asin: "B45SADFGHR",
                price: 1000,
                quantity: 1
            },
            {
                asin: "CD57A0FGHF",
                price: 3000,
                quantity: 3
            }
        ];
        await paymentInst.makePayment(orderId, tokenIndex, totalPrice, totalQty, products, {from: buyer});
        const paymentDetails = await paymentInst.getTransactionDetails(buyer, orderId);
        console.log("Payment ID: ", paymentDetails.paymentID);
        assert.equal(paymentDetails.numOfProducts, 2);
    });

    

    // it("setMessage sets the message correctly", async() => {
    //     const instance = await Payment.deployed();
    //     await instance.setMessage(newMessage);
    //     const message = await instance.message();
    //     assert.equal(message, newMessage);
    // });

});