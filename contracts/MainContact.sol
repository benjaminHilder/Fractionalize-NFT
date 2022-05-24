pragma solidity 0.8.14;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import './FractionToken.sol';

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MainContract is IERC721Receiver {
    uint DEFAULT_WAIT_TIME = 259200; // 3 days;
    uint DEFAULT_PROPOSAL_TO_PASS = 50; //50%

    uint currentLastProposalId;
    uint currentLastAuctionId;

    mapping(address => CurrentDepositedNFTs) nftDeposits;
    mapping(address => uint) tokenBalances;
    uint depositsMade;
    address contractDeployer;

    constructor() {
        depositsMade = 0;
        contractDeployer = msg.sender;
    }

    struct NFTDeposit {
        address owner;
        address NFTContractAddress;
        ERC721 NFT;
        uint256 supply;
        uint256 tokenId;
        uint256 depositTimestamp;
        address fractionContractAddress;
        baseFractionToken fractionToken;
        bool hasFractionalised;
        bool canWithdraw;
        bool isChangingOwnership;
    }

    struct CurrentDepositedNFTs {
        NFTDeposit[] deposits;
    }

    struct allVotingInfo {
        buyoutProposal[] proposals;
        buyoutAuction[] auctions;
    }

    struct buyoutProposal {
        
        bool active;

        NFTDeposit nftDeposit;

        address proposalInitiator;

        uint id;
        uint buyoutPriceStart;
        uint totalVoted;
        uint totalAmountAgree;
        uint totalAmountDisagree;
        uint finishTime;
        
    }
    mapping (address => mapping(uint => bool)) hasVotedInProposal;
    mapping (address => mapping(uint  => bool)) voteValueInProposal;

    struct buyoutAuction {
        bool active;

        NFTDeposit nftDeposit;

        buyoutProposal initialProposal;
        
        address currentBidLeader;

        uint id;
        uint currentBid;
        uint finishTime;
        uint pricePerToken;
    }

    mapping (address => mapping(uint => bool)) hasVotedInAuction;
    mapping (address => mapping(uint => bool)) voteValueInAuction;

    mapping(baseFractionToken => allVotingInfo) AllVotingInfo;
    //mapping(address => mapping(ERC20 => uint)) tokenBalances;

    modifier isProposalOrAuctionNotActive(baseFractionToken token) {
        uint latestProposal = AllVotingInfo[token].proposals.length;
        uint latestAuction = AllVotingInfo[token].auctions.length;

        require(AllVotingInfo[token].proposals[latestProposal].active == false, "Token already in proposal");
        require(AllVotingInfo[token].auctions[latestAuction].active == false, "Token already in auction");
        _;
    }

    modifier contractDeployerOnly {
        require (msg.sender == contractDeployer, "Only contract deployer can call this function");
        _;
    }
    // mapping nft idenifier => address (owner of nft)
    function updateDepositValue() public {
        depositsMade++;
    }

    function stakeTokens(baseFractionToken _tokens, uint _amount) public {
        require(_tokens.balanceOf(msg.sender) <= _amount, "you dont have enough tokens");

        //user needs to approve first

        _tokens.transferFrom(msg.sender, address(this), _amount);
        tokenBalances[msg.sender] += _amount;
    }

    function unstakeTokens(baseFractionToken _tokens, uint _amount) public {
        require(tokenBalances[msg.sender] <= _amount, "you dont have enough tokens");

        tokenBalances[msg.sender] -= _amount;
        _tokens.transfer(msg.sender, _amount);
    }

    function depositNft(address _NFTContractAddress, uint256 _tokenId) public {

        NFTDeposit memory newInfo;
        newInfo.NFT = ERC721(_NFTContractAddress);
        require(newInfo.NFT.ownerOf(_tokenId) == msg.sender, "You do not own this NFT");

        depositsMade++;
        //can this be reentrency
        newInfo.NFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        newInfo.NFTContractAddress = _NFTContractAddress;
        newInfo.owner = msg.sender;
        newInfo.tokenId = _tokenId;
        newInfo.depositTimestamp = block.timestamp;
        newInfo.hasFractionalised = false;
        nftDeposits[msg.sender].deposits.push(newInfo);
    }

    function createFraction(
        address _NFTContractAddress,
        uint256 _tokenId,
        uint256 _royaltyPercentage,
        uint256 _supply,
        string memory _tokenName,
        string memory _tokenTicker
    ) public {
        for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
            //if correct nft to createFraction and we are the owner
            if (nftDeposits[msg.sender].deposits[i].NFTContractAddress ==
                _NFTContractAddress &&
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId &&
                nftDeposits[msg.sender].deposits[i].owner == msg.sender
            ) {

                baseFractionToken fractionToken = new baseFractionToken(
                    msg.sender,
                    _royaltyPercentage,
                    _supply,
                    _tokenName,
                    _tokenTicker,
                    address (this)
                );
                nftDeposits[msg.sender].deposits[i].hasFractionalised = true;
                nftDeposits[msg.sender].deposits[i].fractionToken = fractionToken;
                nftDeposits[msg.sender].deposits[i].fractionContractAddress = address(fractionToken);
                break;
            }
        }
    }

    function withdrawNft(address _NFTContractAddress, uint256 _tokenId) public {
        ERC721 NFTContract = ERC721(_NFTContractAddress);

        for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
            if (nftDeposits[msg.sender].deposits[i].NFT == NFTContract && 
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId)
            {
                //was hasFractionalised
                if(nftDeposits[msg.sender].deposits[_tokenId].canWithdraw) {
                    nftDeposits[msg.sender].deposits[_tokenId].NFT.safeTransferFrom(address(this), msg.sender, _tokenId);
                }

                // if nft owner owns all fractions of NFT
                else if (nftDeposits[msg.sender].deposits[_tokenId].hasFractionalised == true &&
                nftDeposits[msg.sender].deposits[_tokenId].fractionToken.balanceOf(msg.sender) == 
                nftDeposits[msg.sender].deposits[_tokenId].fractionToken.totalSupply()) {
                nftDeposits[msg.sender].deposits[_tokenId].NFT.safeTransferFrom(address(this), msg.sender, _tokenId);
                }
            }
        }
    }

    function updateNftOwner(address _oldOwner, address _newOwner, NFTDeposit memory _nftDeposit) public {
        require(_nftDeposit.isChangingOwnership == true, "NFT is not changing ownership");
        _nftDeposit.owner = _newOwner;
        _nftDeposit.isChangingOwnership = false;
    }

    function buyoutAllTokens(address _NFTContractAddress, uint256 _tokenId) public {
        ERC721 NFTContract = ERC721(_NFTContractAddress);

       //access tokens
        for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
            if (nftDeposits[msg.sender].deposits[i].NFT == NFTContract && 
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId) {

                    baseFractionToken nftFraction = nftDeposits[msg.sender].deposits[i].fractionToken;
                    for (uint j = 0; j < nftFraction.returnTokenOwners().length; j++) {

                    }
                }
            }
    }

    function startBuyoutProposal(baseFractionToken _token, NFTDeposit memory _nftDeposit) isProposalOrAuctionNotActive(_token) public payable{
        buyoutProposal memory newProposal; 
        
        newProposal.finishTime = block.timestamp + DEFAULT_WAIT_TIME;
        newProposal.buyoutPriceStart = msg.value;
        newProposal.proposalInitiator = msg.sender;
        hasVotedInProposal[msg.sender][currentLastProposalId] = true;
        newProposal.totalAmountAgree = _token.balanceOf(msg.sender);
        newProposal.totalAmountDisagree = 0;
        newProposal.totalVoted = _token.balanceOf(msg.sender);
        newProposal.active = true;
        newProposal.nftDeposit = _nftDeposit;
        newProposal.id = currentLastProposalId; 
        AllVotingInfo[_token].proposals.push(newProposal);
        currentLastProposalId++;
    }

    function voteOnProposal(NFTDeposit memory _NFTDeposit, bool _voteValue, uint _voteAmount) public {
        baseFractionToken Token = _NFTDeposit.fractionToken;
        uint latestProposal = AllVotingInfo[Token].proposals.length;
        uint latestAuction = AllVotingInfo[Token].auctions.length;

        uint id = AllVotingInfo[Token].proposals[latestProposal].id;

        require (AllVotingInfo[Token].proposals[latestProposal].active == true, "proposal is not active");
        require (hasVotedInProposal[msg.sender][id] == false, "this user has already voted");

       if (block.timestamp < AllVotingInfo[Token].proposals[latestProposal].finishTime) {
           stakeTokens(AllVotingInfo[Token].proposals[latestProposal].nftDeposit.fractionToken, _voteAmount);
           hasVotedInProposal[msg.sender][id] = true;
           voteValueInProposal[msg.sender][id] = _voteValue;

           AllVotingInfo[Token].proposals[latestProposal].totalVoted += _voteAmount;

           if (_voteValue == true) {
               AllVotingInfo[Token].proposals[latestProposal].totalAmountAgree += _voteAmount;
           } else {
               AllVotingInfo[Token].proposals[latestProposal].totalAmountDisagree += _voteAmount;
           }

           // percentage agree
           if(_NFTDeposit.supply * AllVotingInfo[Token].proposals[latestProposal].totalAmountAgree / 100 
               >= DEFAULT_PROPOSAL_TO_PASS) {
               AllVotingInfo[Token].proposals[latestProposal].active = false;
               startBuyoutAuction(Token, AllVotingInfo[Token].proposals[latestProposal]);
           }
           //percentage disagree
           else if (_NFTDeposit.supply * AllVotingInfo[Token].proposals[latestProposal].totalAmountDisagree / 100 
                   >= DEFAULT_PROPOSAL_TO_PASS) {
                   AllVotingInfo[Token].proposals[latestProposal].active = false;
                   payable(AllVotingInfo[Token].proposals[latestProposal].proposalInitiator).transfer(AllVotingInfo[Token].proposals[latestProposal].buyoutPriceStart);

           }
       } else {
           if (AllVotingInfo[Token].proposals[latestProposal].active == true) {
               AllVotingInfo[Token].proposals[latestProposal].active = false;
           }
       }
    }

    function startBuyoutAuction(baseFractionToken _token, buyoutProposal memory proposal) public {
        currentLastAuctionId++;
        uint latestProposal = AllVotingInfo[_token].proposals.length;

        buyoutAuction memory newAuction;
        newAuction.initialProposal = AllVotingInfo[_token].proposals[latestProposal];
        newAuction.finishTime = block.timestamp + DEFAULT_WAIT_TIME;
        newAuction.currentBid = newAuction.initialProposal.buyoutPriceStart;
        newAuction.currentBidLeader = newAuction.initialProposal.proposalInitiator;
        newAuction.active = true;
        newAuction.nftDeposit = proposal.nftDeposit;
        newAuction.id = currentLastAuctionId;

        AllVotingInfo[_token].auctions.push(newAuction);
    }

    function bidOnAuction(baseFractionToken _token, bool _voteValue) public payable{
        uint latestProposal = AllVotingInfo[_token].proposals.length;
        uint latestAuction = AllVotingInfo[_token].auctions.length;

        if (msg.value <= AllVotingInfo[_token].auctions[latestAuction].currentBid) {
            payable(msg.sender).transfer(msg.value);
        } else { 

            if (block.timestamp < AllVotingInfo[_token].auctions[latestAuction].finishTime) { 

            require (AllVotingInfo[_token].auctions[latestAuction].active == true, "proposal is not active");
            require (AllVotingInfo[_token].proposals[latestProposal].active == false, "this token needs to leave the proposal first");

            uint oldBid = AllVotingInfo[_token].auctions[latestAuction].currentBid;
            address oldLeader = AllVotingInfo[_token].auctions[latestAuction].currentBidLeader;
            AllVotingInfo[_token].auctions[latestAuction].currentBid = msg.value;
            AllVotingInfo[_token].auctions[latestAuction].currentBidLeader = msg.sender;
            payable(oldLeader).transfer(oldBid);

            } else if (AllVotingInfo[_token].auctions[latestAuction].active == true) {
                AllVotingInfo[_token].auctions[latestAuction].active == false;
            }

            AllVotingInfo[_token].auctions[latestAuction].pricePerToken = AllVotingInfo[_token].auctions[latestAuction].currentBid / _token.totalSupply();
            }

            determineAuctionWinner(AllVotingInfo[_token].auctions[latestAuction], AllVotingInfo[_token].auctions[latestAuction].nftDeposit);
            AllVotingInfo[_token].auctions[latestAuction].active = false; 
    }

    function determineAuctionWinner(buyoutAuction memory _auction, NFTDeposit memory _nftDeposit) private {
        _nftDeposit.isChangingOwnership = true;
        updateNftOwner(_nftDeposit.owner, _auction.currentBidLeader, _nftDeposit);
        _nftDeposit.isChangingOwnership = false;

        _nftDeposit.fractionToken.updateNFTOwner(_auction.currentBidLeader);
    }

    //add non reentract modifier
    function claimFromBuyoutTokens(baseFractionToken _token, uint _amount) public  {
        uint latestAuction = AllVotingInfo[_token].auctions.length;

        require(AllVotingInfo[_token].auctions[latestAuction].active == false, "auction still active");

        _token.transferFrom(msg.sender, address(this), _amount);
        _token.burn(_amount);
        payable(msg.sender).transfer(AllVotingInfo[_token].auctions[latestAuction].pricePerToken * _amount);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        // require(from == address(), "Cannot send nfts to Vault dirrectly");

        return IERC721Receiver.onERC721Received.selector;
    }
}
