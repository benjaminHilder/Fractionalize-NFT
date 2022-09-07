pragma solidity 0.8.14;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import './FractionToken.sol';

contract FractionaliseNFT is IERC721Receiver {
    mapping(address => DepositFolder) AccessDeposits;

    //storage folder that can be expanded to hold more structs and then be accessed by a mapping (nftDeposits)
    struct DepositFolder {
        DepositInfo[] Deposit;
    }

    struct DepositInfo {
        address owner;
        address nftContractAddress;
        uint256 nftId; 
        uint256 depositTimestamp; //deposited time
        
        //post fractionalise info
        address fractionContractAddress; 
        uint256 supply;

        bool hasFractionalised; //has deposited nft been fractionaliseds
        bool canWithdraw;
        bool isChangingOwnership; //used for the auction contract
    }

    function depositNft(address _NFTContractAddress, uint256 _tokenId) public {
        //address must approve this contract to transfer the nft they own before calling this function
        //fractionalise contract needs to hold the nft so it can be fractionalise
        ERC721 NFT = ERC721(_NFTContractAddress);
        NFT.safeTransferFrom(msg.sender, address(this), _tokenId);

        DepositInfo memory newDeposit;

        newDeposit.owner = msg.sender;
        newDeposit.nftContractAddress = _NFTContractAddress;
        newDeposit.nftId = _tokenId;
        newDeposit.depositTimestamp = block.timestamp;

        newDeposit.hasFractionalised = false;
        newDeposit.canWithdraw = true;

        //save the new infomation into the smart contract
        AccessDeposits[msg.sender].Deposit.push(newDeposit);
    }

    function createFraction(
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _royaltyPercentage,
        uint256 _supply,
        string memory _tokenName,
        string memory _tokenTicker
    ) public {
        
        //search for deposited NFT as well make sure the caller is the owner of that NFT
        for (uint256 i = 0; i < AccessDeposits[msg.sender].Deposit.length; i++) {
            if (AccessDeposits[msg.sender].Deposit[i].nftContractAddress == _nftContractAddress &&
                AccessDeposits[msg.sender].Deposit[i].nftId == _nftId &&
                AccessDeposits[msg.sender].Deposit[i].owner == msg.sender)

            //if so create a new fractionalise ERC20 token
            //fraction ERC20 mints all tokens to owner on constructor
            {
                AccessDeposits[msg.sender].Deposit[i].hasFractionalised = true;
                AccessDeposits[msg.sender].Deposit[i].canWithdraw = false;

                FractionToken fractionToken = new FractionToken(
                    _nftContractAddress,
                    _nftId,
                    msg.sender,
                    _royaltyPercentage,
                    _supply,
                    _tokenName,
                    _tokenTicker
                );
                AccessDeposits[msg.sender].Deposit[i].fractionContractAddress = address(fractionToken);
                break;
            }
        }
    }


    ////if the sender of this transaction has the total supply of fraction tokens or the nft has not be fractionalise, allow withdraw
    //function withdrawNft(address _NFTContractAddress, uint256 _tokenId, address _TokenContractAddress) public {
    //    //instance of fraction token via fraction token address
    //    FractionToken FractionToken = FractionToken(_TokenContractAddress);
    //    
    //    //loop over saved data (NFTDeposit struct) under the address that send that sent this transaction
    //    for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
    //        
    //        //if function arguments match (deposited NFT we are searching for)
    //        if (nftDeposits[msg.sender].deposits[i].NFTContractAddress == _NFTContractAddress &&
    //            nftDeposits[msg.sender].deposits[i].tokenId == _tokenId) {
    //                
    //                //if the sender of this transaction has the total supply of fraction tokens 
    //                //or the nft has not be fractionalise
    //                if (nftDeposits[msg.sender].deposits[i].hasFractionalised == false||
    //                    FractionToken.balanceOf(msg.sender) == FractionToken.totalSupply())
    //                    {
    //                        //transfer to owner
    //                        nftDeposits[msg.sender].deposits[_tokenId].NFT.safeTransferFrom(address(this), msg.sender, _tokenId);
    //                        break;
    //                    }
    //            }
    //    }
    //}

    //for testing
    //function getFractionContractAddress(address _address, uint _depositIndex) public view returns (address) {
    //    return nftDeposits[_address].deposits[_depositIndex].fractionContractAddress;
    //}
//
    ////for testing
    //function getNftDeposit(address _address) public view returns (NFTDeposit[] memory) {
    //    return nftDeposits[_address].deposits;
    //}
//
    ////for testing
    //function getLastFractionId(address _address) public view returns(uint) {
    //    return nftDeposits[_address].deposits.length;
    //}

    //required function for ERC721
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