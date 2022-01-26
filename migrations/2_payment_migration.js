const Payment = artifacts.require("Payment");

module.exports = function (deployer, network, accounts) {
    const wallet = accounts[1];
    deployer.deploy(Payment, wallet, {from: accounts[0]});
};
