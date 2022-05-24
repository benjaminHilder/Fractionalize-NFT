const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const MainContract = artifacts.require("MainContract");
const NFTContract = artifacts.require("MyToken");
const FractionToken = artifacts.require("baseFractionToken");

module.exports = async function (deployer, _network, accounts) {
    await deployer.deploy(MainContract);
    await deployer.deploy(NFTContract);
    //await deployer.deploy(accounts[0], 8, 800, "tokenName", "TT", MainContract);
}