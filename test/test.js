const { expectRevert } = require("@openzeppelin/test-helpers");
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

    it('should run the transfer', async() => {
        await mainContract.depositNft(nftContract.address, 0, {from: accounts[0]})
        await mainContract.createFraction(nftContract.address, 0, 8, 8000, "tokens", "ts", {from: accounts[0]})
//       
        console.log(accounts[0].address)
        //console.log(await mainContract.getFractionContractAddress(0, {from: accounts[0]}).)
        //const newFractionContractAddress = await mainContract.getFractionContractAddress(0, {from: accounts[0]});
        //var fractionInstance = await FractionToken.at(newFractionContractAddress)
////
        //fractionInstance.transfer(accounts[1], 1, {from: accounts[0]});
////
        //await expectRevert (
        //    mainContract.withdrawNft(nftContract.address, 0, {from: accounts[0]}),
        //    'shouldnt be able to withdrawNft due to the owner not owning all the erc20 token'
        //)
////
        //fractionInstance.transfer(accounts[0], 1, {from:account[1]});
////
        //mainContract.withdrawNft(nftContract.address, 0, {from: accounts[0]})

    })
})