pragma solidity 0.8.14;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import './FractionToken.sol';

contract MainContract is IERC721Receiver {
    mapping(address => CurrentDepositedNFTs) nftDeposits;

    struct NFTDeposit {
        address owner;
        address NFTContractAddress;
        ERC721 NFT;
        uint256 supply;
        uint256 tokenId; //NFT ID that was deposited
        uint256 depositTimestamp; //deposited time
        address fractionContractAddress; //address to fraction contract of nft
        FractionToken fractionToken;
        bool hasFractionalised; //has deposited nft been fractionaliseds
        bool canWithdraw;
        bool isChangingOwnership; //used for the auction contract
    }

    //storage folder that can be expanded to hold more structs and then be accessed by a mapping (nftDeposits)
    struct CurrentDepositedNFTs {
        NFTDeposit[] deposits;
    }

    function depositNft(address _NFTContractAddress, uint256 _tokenId) public {
        //address must approve this contract to transfer the nft they own before calling this function

        //create a new struct object with the relevent deposit info
        NFTDeposit memory newDeposit;
        newDeposit.NFT = ERC721(_NFTContractAddress);

        //this contract needs to hold the nft so it can be fractionalise
        newDeposit.NFT.safeTransferFrom(msg.sender, address(this), _tokenId);

        newDeposit.NFTContractAddress = _NFTContractAddress;
        newDeposit.owner = msg.sender;
        newDeposit.tokenId = _tokenId;

        //current time of deposit
        newDeposit.depositTimestamp = block.timestamp;

        newDeposit.hasFractionalised = false;
        newDeposit.canWithdraw = true;

        //save the new infomation into the smart contract
        nftDeposits[msg.sender].deposits.push(newDeposit);
    }

    function createFraction(
        address _NFTContractAddress,
        uint256 _tokenId,
        uint256 _royaltyPercentage,
        uint256 _supply,
        string memory _tokenName,
        string memory _tokenTicker
    ) public {

        //loop over saved data (NFTDeposit struct) under the address that send that sent this transaction
        for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {

            //if function arguments (deposited NFT we are searching for)
            if (nftDeposits[msg.sender].deposits[i].NFTContractAddress ==
                _NFTContractAddress &&
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId &&
                nftDeposits[msg.sender].deposits[i].owner == msg.sender) 
            {
                //instantiate a new fraction token & set the correct data
                FractionToken fractionToken = new FractionToken(
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


    //if the sender of this transaction has the total supply of fraction tokens or the nft has not be fractionalise, allow withdraw
    function withdrawNft(address _NFTContractAddress, uint256 _tokenId, address _TokenContractAddress) public {
        //instance of fraction token via fraction token address
        FractionToken FractionToken = FractionToken(_TokenContractAddress);
        
        //loop over saved data (NFTDeposit struct) under the address that send that sent this transaction
        for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
            
            //if function arguments match (deposited NFT we are searching for)
            if (nftDeposits[msg.sender].deposits[i].NFTContractAddress == _NFTContractAddress &&
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId) {
                    
                    //if the sender of this transaction has the total supply of fraction tokens 
                    //or the nft has not be fractionalise
                    if (nftDeposits[msg.sender].deposits[i].hasFractionalised == false||
                        FractionToken.balanceOf(msg.sender) == FractionToken.totalSupply())
                        {
                            //transfer to owner
                            nftDeposits[msg.sender].deposits[_tokenId].NFT.safeTransferFrom(address(this), msg.sender, _tokenId);
                            break;
                        }
                }
        }
    }

    //for testing
    function getFractionContractAddress(address _address, uint _depositIndex) public view returns (address) {
        return nftDeposits[_address].deposits[_depositIndex].fractionContractAddress;
    }

    //for testing
    function getNftDeposit(address _address) public view returns (NFTDeposit[] memory) {
        return nftDeposits[_address].deposits;
    }

    //for testing
    function getLastFractionId(address _address) public view returns(uint) {
        return nftDeposits[_address].deposits.length;
    }

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