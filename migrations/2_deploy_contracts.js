const Company = artifacts.require("Company");

module.exports = function (deployer, networks, accounts) {
    const account = accounts[0];
    console.log("account 0 : ",account);
    deployer.deploy(Company, account);
};
