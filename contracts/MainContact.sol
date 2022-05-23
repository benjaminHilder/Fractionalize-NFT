pragma solidity 0.8.14;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import './FractionToken.sol';

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MainContract is IERC721Receiver {
    const DEFAULT_WAIT_TIME = 259200; // 3 days;
    const DEFAULT_PROPOSAL_TO_PASS = 50; //50%

    mapping(address => CurrentDepositedNFTs) nftDeposits;
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
        uint256 tokenId;
        uint256 depositTimestamp;
        baseFractionToken fractionContract;
        address fractionContractAddress;
        ERC20 fractionToken;
        bool hasFractionalised;
        bool canWithdraw;
    }

    struct CurrentDepositedNFTs {
        NFTDeposit[] deposits;
    }

    struct allVotingInfo {
        buyoutProposals[] proposals;
        buyoutAuctions[] auctions;
    }

    struct buyoutProposal {
        bool active;

        address proposalInitiator;

        uint buyoutPriceStart;
        uint totalVoted;
        uint totalAmountAgree;
        uint totalAmountDisagree;
        uint finishTime;
        
        mapping (address => bool) hasVoted;
        mapping (address => bool) voteValue;
    }

    struct buyoutAuction {
        bool active;

        buyoutProposal initialProposal;
        
        address currentBidLeader;

        uint currentBid;
        uint finishTime;
        uint pricePerToken;
        
        mapping (address => bool) hasVoted;
    }
    mapping(ERC20 => allVotingInfo) AllVotingInfo;
    //mapping(address => mapping(ERC20 => uint)) tokenBalances;

    modifier isInProposalOrAuction(ERC20 _ERC20) {
        require(isInProposal[_ERC20] == false, "Token already in proposal");
        require(isInAuction[_ERC20] == false, "Token already in auction");
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
    function depositNft(address _NFTContractAddress, uint256 _tokenId) public {

        NFTDeposit memory newInfo;
        newInfo.NFT = ERC721(_NFTContractAddress);
        require( newInfo.NFT.ownerOf(_tokenId) == msg.sender, "You do not own this NFT");
        
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

                baseFractionToken fractToken = new baseFractionToken(
                    msg.sender,
                    //nftDeposits[msg.sender].deposits[i].NFTContractAddress,
                    //nftDeposits[msg.sender].deposits[i].tokenId,
                    _royaltyPercentage,
                    _supply,
                    _tokenName,
                    _tokenTicker
                );
                nftDeposits[msg.sender].deposits[i].hasFractionalised = true;
                nftDeposits[msg.sender].deposits[i].fractionContract = fractToken;
                nftDeposits[msg.sender].deposits[i].fractionContractAddress = address(fractToken);
                nftDeposits[msg.sender].deposits[i].fractionToken = ERC20(nftDeposits[msg.sender].deposits[i].fractionContractAddress);
                //newTokenAddress = address(newFraction);
                break;
            }
        }
    }

    function withdrawNft(address _NFTContractAddress, uint256 _tokenId) public {
        //add require can withdraw
        ERC721 NFTContract = ERC721(_NFTContractAddress);

        //delete withdrawing nft from vault
        for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
            if (nftDeposits[msg.sender].deposits[i].NFT == NFTContract && 
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId)
            {
                if(nftDeposits[msg.sender].deposits[_tokenId].hasFractionalised == false) {
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
        //parentContract.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function buyoutAllTokens(address _NFTContractAddress, uint256 _tokenId) public {
        ERC721 NFTContract = ERC721(_NFTContractAddress);

       //access tokens
        for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
            if (nftDeposits[msg.sender].deposits[i].NFT == NFTContract && 
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId) {

                    ERC20 nftFraction = nftDeposits[msg.sender].deposits[i].ERC20;
                    for (uint j = 0; j < nftFraction.returnTokenOwners(); j++) {

                    }
                }
            }
    }

    function startBuyoutProposal(ERC20 _ERC20) isInProposalOrAuction(_ERC20) public payable{
        buyoutProposal memory newProposal;

        newProposal.finishTime = block.timestamp += DEFAULT_WAIT_TIME;
        newProposal.buyoutPriceStart = msg.value;
        newProposal.proposalInitiator = msg.sender;
        newProposal.hasVoted[msg.sender] = true;
        newProposal.voteValue[msg.sender] = true;
        newProposal.totalAmountAgree = _ERC20.balanceOf(msg.sender);
        newProposal.totalAmountDisagree = 0;
        newProposal.totalVoted = _ERC20.balanceOf(msg.sender);
        newProposal.active = true;

        AllVotingInfo[_ERC20].proposals.push(newProposal);
    }

    function voteOnProposal(ERC20 _ERC20, bool _voteValue) public {
        uint latestProposal = AllVotingInfo[_ERC20].proposals.length;
        uint latestAuction = AllVotingInfo[_ERC20].auctions.length;

        require (AllVotingInfo[_ERC20].proposals[latestProposal].active == true, "proposal is not active");
        require (AllVotingInfo[_ERC20].proposals[latestProposal].hasVoted[msg.sender] == false, "this user has already voted");

        if (block.timestamp < AllVotingInfo[_ERC20].proposal[latestProposal].finishTime) {
            AllVotingInfo[_ERC20].proposals[latestProposal].hasVoted[msg.sender] = true;
            AllVotingInfo[_ERC20].proposals[latestProposal].voteValue[msg.sender] = _voteValue;
            AllVotingInfo[_ERC20].proposals[latestProposal].totalVoted += _ERC20.balanceOf(msg.sender);

            if (_vote == true) {
                AllVotingInfo[_ERC20].proposals[latestProposal].totalAmountAgree += _ERC20.balanceOf(msg.sender);
            } else {
                AllVotingInfo[_ERC20].proposals[latestProposal].totalAmountDisagree += _ERC20.balanceOf(msg.sender);
            }

            // percentage agree
            if(_ERC20.totalSupply * AllVotingInfo[_ERC20].proposals[latestProposal].totalAmountAgree / 100 
                >= DEFAULT_PROPOSAL_TO_PASS) {
                AllVotingInfo[_ERC20].proposals[latestProposal].active = false;
                startBuyoutAuction(_ERC20);
            }
            //percentage disagree
            else if (_ERC20.totalSupply * AllVotingInfo[_ERC20].proposals[latestProposal].totalAmountDisagree / 100 
                    >= DEFAULT_PROPOSAL_TO_PASS) {
                    AllVotingInfo[_ERC20].proposals[latestProposal].active = false;
                    AllVotingInfo[_ERC20].proposals[latestProposal].proposalInitiator.transfer(AllVotingInfo[_ERC20].proposals[latestProposal].buyoutPriceStart);

            }
        } else {
            if (AllVotingInfo[_ERC20].proposals[latestProposal].active == true) {
                AllVotingInfo[_ERC20].proposals[latestProposal].active = false;
            }
        }

    }

    function startBuyoutAuction(ERC20 _ERC20) public {
        uint latestProposal = AllVotingInfo[_ERC20].proposals.length;

        buyoutAuction memory newAuction;
        newAuction.initialProposal = AllVotingInfo[_ERC20].proposals[latestProposal];
        newAuction.finishTime = block.timestamp += DEFAULT_WAIT_TIME;
        newAuction.currentBid = newAuction.initialProposal.buyoutPriceStart;
        newAuction.currentBidLeader = newAuction.initialProposal.proposalInitiator;
        newAuction.active = true;

        AllVotingInfo[_ERC20].auctions.push(newAuction);
    }

    function bidOnAuction(ERC20 _ERC20, bool _voteValue) public payable{
        uint latestProposal = AllVotingInfo[_ERC20].proposals.length;
        uint latestAuction = AllVotingInfo[_ERC20].auctions.length;

        if (msg.value <= AllVotingInfo[_ERC20].auction[latestAuction].currentBid) {
            msg.sender.transfer(msg.value);
        } else { 

            if (block.timestamp < AllVotingInfo[_ERC20].auction[latestAuction].finishTime) { 
            
            require (AllVotingInfo[_ERC20].auction[latestAuction].active == true, "proposal is not active");
            require (AllVotingInfo[_ERC20].auction[latestAuction].hasVoted[msg.sender] == false, "this user has already voted");
            require (AllVotingInfo[_ERC20].proposal[latestProposal].active == false, "this token needs to leave the proposal first");

            uint oldBid = AllVotingInfo[_ERC20].auction[latestAuction].currentBid;
            address oldLeader = AllVotingInfo[_ERC20].auction[latestAuction].currentBidLeader;
            AllVotingInfo[_ERC20].auction[latestAuction].currentBid = msg.value;
            AllVotingInfo[_ERC20].auction[latestAuction].currentBidLeader = msg.sender;
            oldLeader.transfer(oldBid);

            } else if (AllVotingInfo[_ERC20].auction[latestAuction].active == true) {
                AllVotingInfo[_ERC20].auction[latestAuction].active == false;
            }
            
            AllVotingInfo[_ERC20].auction[latestAuction].pricePerToken = AllVotingInfo[_ERC20].auction[latestAuction].currentBid / _ERC20.totalSupply();
        }
    }

    function claimFromBuyoutTokens(ERC20 _ERC20, uint _amount) public nonReentract() {
        uint latestAuction = AllVotingInfo[_ERC20].auctions.length;
    
        require(AllVotingInfo[_ERC20].auction[latestAuction].active == false, "auction still active");

        _ERC20.transferFrom(msg.sender, address(this), _amount);
        _ERC20.burn(_amount);
        msg.sender.transfer(AllVotingInfo[_ERC20].auction[latestAuction].pricePerToken * _amount);
    }

    function changeVoteOnProposalOrAuction(ERC20 _ERC20, bool _newVoteValue) public {
        require (isInProposal[_ERC20] == true || isInAuction[_ERC20] == true, 
        "ERC20 needs to be in proposal or auction first");
        
        if (isInProposal[_ERC20] == true) {
            require (hasVotedInProposal[_ERC20][msg.sender] == true, 
            "this user needs to vote first");

            require (buyoutProposals[_ERC20].voteValue[msg.sender] == true && _newVoteValue == false ||
                     buyoutProposals[_ERC20].voteValue[msg.sender] == false && _newVoteValue == true,
            "this user is not changing their current vote");

            if (_newVoteValue == true ) {
                buyoutProposals[_ERC20].totalAmountDisagree -= _ERC20.balanceOf(msg.sender);
                buyoutProposals[_ERC20].totalAmountAgree += _ERC20.balanceOf(msg.sender);
            }
            else {
                buyoutProposals[_ERC20].totalAmountAgree -= _ERC20.balanceOf(msg.sender);
                buyoutProposals[_ERC20].totalAmountDisagree += _ERC20.balanceOf(msg.sender);
            }
        } else {

            require (hasVotedInAuction[_ERC20][msg.sender] == true, 
            "this user needs to vote first");
            
            require (buyoutAuctions[_ERC20].voteValue[msg.sender] == true && _newVoteValue == false ||
                     buyoutAuctions[_ERC20].voteValue[msg.sender] == false && _newVoteValue == true,
            "this user is not changing their current vote");

            if (_newVoteValue == true ) {
                buyoutAuctions[_ERC20].totalAmountDisagree -= _ERC20.balanceOf(msg.sender);
                buyoutAuctions[_ERC20].totalAmountAgree += _ERC20.balanceOf(msg.sender);
            }
            else {
                buyoutAuctions[_ERC20].totalAmountAgree -= _ERC20.balanceOf(msg.sender);
                buyoutAuctions[_ERC20].totalAmountDisagree += _ERC20.balanceOf(msg.sender);
            }
        }
    }



    

  // function getNftDepositsMapping(address _inputAddress) public view returns (CurrentDepositedNFTs memory) {
   //    return nftDeposits[_inputAddress];
   //}

   //function getCertainNftDeposits(address _inputAddress, uint _index) public view returns (NFTDeposit memory) {
   //    return nftDeposits[_inputAddress].deposits[_index];
   //}

   function getFractionContractAddress(uint _index) public view returns(address) {
       return nftDeposits[msg.sender].deposits[_index].fractionContractAddress;
   }

   function getArraySize() public view returns(uint) {
       return nftDeposits[msg.sender].deposits.length;
   }

   function getDepositsMade() public view returns(uint) {
       return depositsMade;
   }

   //function getFraction(uint _index) public view returns (baseFractionToken) {
   //    return nftDeposits[msg.sender].deposits[_index].fractionContract;
   //}

   //function getFractionNFTOwner(uint _index) public view returns (address) {
   //    return nftDeposits[msg.sender].deposits[_index].fractionContract.getNFTOwner();
   //}

    

    //function mintNewFractionTokens() public {
    //    new baseFractionToken(msg.sender, 10, 8000, "yesToken", "YT");
    //}

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
