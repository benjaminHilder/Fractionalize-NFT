const { web3 } = require("@openzeppelin/test-helpers/src/setup");

const MainContract = artifacts.require("MainContract");
const NFTContract = artifacts.require("NFTGenerator");


module.exports = async function (deployer, _network, accounts) {
    await deployer.deploy(MainContract);
    await deployer.deploy(NFTContract);
    //await deployer.deploy(accounts[0], 8, 800, "tokenName", "TT", MainContract);
}