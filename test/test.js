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
    let iterator = 0;
    
    beforeEach(async () => {
        mainContract = await MainContract.deployed();
        nftContract = await NFTContract.deployed();

        await nftContract.safeMint(accounts[0], iterator, {from: accounts[0]})
        await nftContract.approve(MainContract.address, iterator, {from: accounts[0]})
        await mainContract.depositNft(nftContract.address, iterator, {from: accounts[0]});
    })

    it('should be able to deposit', async() => {
        let nftDeposit = await mainContract.getNftDeposit(accounts[0])
        assert(nftDeposit.length == 1)

        iterator++;
    })

    it('should be able to create fraction', async() => {
        await mainContract.createFraction(nftContract.address, iterator, 8, 8000, "tokenName", "TK", {from: accounts[0]});

        let nftDeposit = await mainContract.getNftDeposit(accounts[0])
        let fractionContractAddress = await nftDeposit[iterator].fractionContractAddress;

        let fractionInstance = await FractionToken.at(fractionContractAddress);
        
        let supply = await fractionInstance.totalSupply();
        let balance = await fractionInstance.balanceOf(accounts[0]);

        assert(supply == 8000)
        assert(balance == 8000);

        iterator++;
    }) 

    it("should be able to withdraw nft", async() => {
        await mainContract.withdrawNft(nftContract.address, iterator, {from: accounts[0]});

        let ownerOfNft = await nftContract.ownerOf(iterator)
        assert(ownerOfNft == await accounts[0])

        iterator++;
    })

    it('SHOULDNT be able to create a fraction of an NFT that you havent deposited', async() => {
        await nftContract.safeMint(accounts[0], 99, {from: accounts[0]})
        await mainContract.createFraction(nftContract.address, 99, 8, 8000, "tokenName", "TK", {from: accounts[0]})
        
        let nftDeposit = await mainContract.getNftDeposit(accounts[0])

        try {
            let frac = await nftDeposit[99].fractionContractAddress;
        } catch(e) {
            console.log("failed to retrieve fraction contract address");
        }

        iterator++;
    })

    it('SHOULDNT be able to create a fraction of an NFT  that you do not own', async() => {
        await mainContract.createFraction(nftContract.address, iterator, 8, 8000, "tokenName", "TK", {from: accounts[1]})
        let nftDeposit = await mainContract.getNftDeposit(accounts[1])

        try {
            let frac = await nftDeposit[iterator].fractionContractAddress;
        } catch(e) {
            console.log("failed to retrieve fraction contract address");
        }

        iterator++;
    })


    it("SHOULDNT be able to send nft after to has been fractionalised", async() => {
        await mainContract.createFraction(nftContract.address, iterator, 8, 8000, "tokenName", "TK", {from: accounts[0]});
  
        await mainContract.withdrawNft(nftContract.address, iterator, {from: accounts[0]})
        let ownerOf = await nftContract.ownerOf(iterator);
        assert(ownerOf == mainContract.address)
        iterator++;
    })
})