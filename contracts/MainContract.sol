pragma solidity 0.8.14;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import './FractionToken.sol';

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MainContract is IERC721Receiver {
    mapping(address => CurrentDepositedNFTs) nftDeposits;

    uint depositsMade;
    address contractDeployer;
    address lastAddress;

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

    modifier contractDeployerOnly {
        require (msg.sender == contractDeployer, "Only contract deployer can call this function");
        _;
    }

    function depositNft(address _NFTContractAddress, uint256 _tokenId) public {

        NFTDeposit memory newInfo;
        newInfo.NFT = ERC721(_NFTContractAddress);
        //require(newInfo.NFT.ownerOf(_tokenId) == msg.sender, "You do not own this NFT");
        //can this be reentrency
        newInfo.NFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        newInfo.NFTContractAddress = _NFTContractAddress;
        newInfo.owner = msg.sender;
        newInfo.tokenId = _tokenId;
        newInfo.depositTimestamp = block.timestamp;
        newInfo.hasFractionalised = false;
        newInfo.canWithdraw = true;
        nftDeposits[msg.sender].deposits.push(newInfo);
        lastAddress = msg.sender;
    }

    address nftContractAddress;
    address inputContractAddress;

    uint tokenId;
    uint inputTokenId;

    address ownerOf;
    address msgsender;

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
                nftDeposits[msg.sender].deposits[i].owner == msg.sender) 
            {

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

     function withdrawNft(address _NFTContractAddress, uint256 _tokenId, address _TokenContractAddress) public {
        CurrentDepositedNFTs memory userDeposits = nftDeposits[msg.sender];
        baseFractionToken FractionToken = baseFractionToken(_TokenContractAddress);
        
        for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
            if (nftDeposits[msg.sender].deposits[i].NFTContractAddress == _NFTContractAddress &&
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId) {
                    uint totalSupply = FractionToken.totalSupply();

                    if (userDeposits.deposits[i].hasFractionalised == false||
                        FractionToken.balanceOf(msg.sender) == totalSupply)
                        {
                            nftDeposits[msg.sender].deposits[_tokenId].NFT.safeTransferFrom(address(this), msg.sender, _tokenId);
                            break;
                        }
                }
        }
    }
    function getFractionContractAddress(address _address, uint _depositIndex) public view returns (address) {
        return nftDeposits[_address].deposits[_depositIndex].fractionContractAddress;
    }

    function getNftDeposit(address _address) public view returns (NFTDeposit[] memory) {
        return nftDeposits[_address].deposits;
    }

    function getLastFractionId(address _address) public view returns(uint) {
        return nftDeposits[_address].deposits.length;
    }

    function searchForFractionToken(address _NFTContractAddress, uint256 _tokenId) public view returns(baseFractionToken) {
         for (uint256 i = 0; i < nftDeposits[msg.sender].deposits.length; i++) {
            if (nftDeposits[msg.sender].deposits[i].NFTContractAddress == _NFTContractAddress &&
                nftDeposits[msg.sender].deposits[i].tokenId == _tokenId) {
                    return nftDeposits[msg.sender].deposits[i].fractionToken;
                }
         }
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