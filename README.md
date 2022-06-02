### Fractionalise NFT to ERC20 Tokens
Turn an ERC271 into multiple ERC20. ERC20 can then be used to other dapps that use ERC20 tokens for example uniswap.
Coming soon: Auction to un-fractionalise your NFT

Dapp: https://nft-fractionalise.on.fleek.co/

How to use dapp:
1) Connect wallet with the rinkeby network
2) Mint sample NFT on the left side (sample NFT not required)
3) Type the contract address of your NFT and ID as well as what you want the new ERC20 fraction token to be called, token ticker, supply amount (add 18 zeros after desired supply amount) and royalty fee on transfer
4) Click approve the contract and accept the transaction
5) Click deposit NFT and accept the transaction
6) Click fractionalise NFT and accept the transaction
7) Place fraction id into "Get Fraction Address area" to receive the contract address for your new ERC20 fractionalised tokens
8) With this contract address you can enter it into your wallet to see your balance. You can also use it in any other dapp that accepts ERC20 for example Uniswap to add a liquidity pool so people can start trading your new ERC20 fractionalised token
9) If you want to withdraw your NFT from the contract you can do so if you own all the ERC20 fractions. You can do this by entering the NFT contract address, fraction address and NFT ID. Click withdraw and accept the transaction
10) If you want to withdraw your NFT but do not own all the ERC20 fraction addresses, this is coming soon with an auction mechanic. This mechanic will allow users to start a proposal to request a base buyout of all the tokens. If 50% or more of the tokens accept this proposal an auction will commence. Any user that wants to buy the NFT can do so by bidding in the auction. Once the auction has finished the winner can claim the NFT. Every token holder will be able to claim funds based on how many tokens are in their wallet. The code for the auction is in this repo under contracts/ReclaimNftAuction.sol. It currently needs a few changes but a majority of the code is working.

### What I used to develop it:

> * nodejs
> * npm
> * solidity
> * javascript
> * truffle
> * metamask
> * react
> * openzeppelin
