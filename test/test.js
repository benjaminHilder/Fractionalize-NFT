const { expectRevert } = require("@openzeppelin/test-helpers");
const { assertion } = require("@openzeppelin/test-helpers/src/expectRevert");
const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const { default: Web3 } = require("web3");

const MainContract = artifacts.require("MainContract");
const FractionToken = artifacts.require("baseFractionToken");
const NFTContract = artifacts.require("MyToken");

contract ('MainContract', (accounts) => {
    let mainContract;
    let nftContract;
    beforeEach(async () => {
        mainContract = await MainContract.deployed();
        nftContract = await NFTContract.deployed();
        nftContract.safeMint(accounts[0], 0, {from: accounts[0]})
        nftContract.approve(MainContract.address, 0, {from: accounts[0]})
    })

    it('should be able to depost, fractionalise, access fractions', async() => {
        nftContract.depositNft(nftContract, 0, {from: accounts[0]});
        assert(mainContract.nftDeposits[accounts[0]].deposits.length == 1)

    })
})