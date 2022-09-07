pragma solidity 0.8.14;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import './FractionToken.sol';

contract FractionalizeNFT is IERC721Receiver {
    mapping(address => DepositFolder) AccessDeposits;
    mapping(address => mapping (uint256 => uint256)) NftIndex;

    //storage folder that can be expanded to hold more structs and then be accessed by a mapping (nftDeposits)
    struct DepositFolder {
        DepositInfo[] Deposit;
    }

    struct DepositInfo {
        address owner;
        address nftContractAddress;
        uint256 nftId; 
        uint256 depositTimestamp; //deposited time
        
        //post fractionalize info
        address fractionContractAddress; 
        uint256 supply;

        bool hasFractionalized; //has deposited nft been fractionalizeds
    }

    function depositNft(address _nftContractAddress, uint256 _nftId) public {
        //address must approve this contract to transfer the nft they own before calling this function
        //fractionalize contract needs to hold the nft so it can be fractionalize
        ERC721 NFT = ERC721(_nftContractAddress);
        NFT.safeTransferFrom(msg.sender, address(this), _nftId);

        DepositInfo memory newDeposit;

        newDeposit.owner = msg.sender;
        newDeposit.nftContractAddress = _nftContractAddress;
        newDeposit.nftId = _nftId;
        newDeposit.depositTimestamp = block.timestamp;

        newDeposit.hasFractionalized = false;

        //set index location of nft in nft folder to prevent the need of for loops when accessing deposit information
        NftIndex[_nftContractAddress][_nftId] = AccessDeposits[msg.sender].Deposit.length;

        //save the new infomation into the smart contract
        AccessDeposits[msg.sender].Deposit.push(newDeposit);
    }

    function createFraction(
        address _nftContractAddress,
        uint256 _nftId,
        uint256 _royaltyPercentage,
        uint256 _supply,
        string memory _tokenName,
        string memory _tokenTicker) 
        public {
        
        uint256 index = NftIndex[_nftContractAddress][_nftId];
        require(AccessDeposits[msg.sender].Deposit[index].owner == msg.sender, "Only the owner of this NFT can access it");
            
        AccessDeposits[msg.sender].Deposit[index].hasFractionalized = true;

        FractionToken fractionToken = new FractionToken(_nftContractAddress,
                                                        _nftId,
                                                        msg.sender,
                                                        _royaltyPercentage,
                                                        _supply,
                                                        _tokenName,
                                                        _tokenTicker
                                                        );

        AccessDeposits[msg.sender].Deposit[index].fractionContractAddress = address(fractionToken);
    }

    //can withdraw the NFT if you own the total supply
    function withdrawNftWithSupply(address _fractionContract) public {
        //address must approve this contract to transfer fraction tokens
        
        FractionToken fraction = FractionToken(_fractionContract);

        require(fraction.ContractDeployer() == address(this), "Only fraction tokens created by this fractionalize contract can be accepted");
        require(fraction.balanceOf(msg.sender) == fraction.totalSupply());

        address NFTAddress = fraction.NFTAddress();
        uint256 NFTId = fraction.NFTId();

        //remove tokens from existence as they are no longer valid (NFT leaving this contract)
        fraction.transferFrom(msg.sender, address(this), fraction.totalSupply());
        fraction.burn(fraction.totalSupply());

        ERC721 NFT = ERC721(NFTAddress);
        NFT.safeTransferFrom(address(this), msg.sender, NFTId);

        uint256 index = NftIndex[NFTAddress][NFTId];
        delete AccessDeposits[msg.sender].Deposit[index];
    }

    function withdrawNftNotFractionalized(address _NftContract, address _NftId) public {
        uint256 index = NftIndex[_NftContract][_NftId];
        require (AccessDeposits[msg.sender].Deposit[index].hasFractionalized == false, "Only if the NFT hasn't been fractionalise can you withdraw the NFT with this function");
        require (AccessDeposits[msg.sender].Deposit[index].owner == msg.sender, "Only the NFT owner can call this function");

        ERC721 NFT = ERC721(_NftContract);
        NFT.safeTransferFrom(address(this), msg.sender, _NftId);

        delete AccessDeposits[msg.sender].Deposit[index];
    }

    //required function for ERC721
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {        
        return IERC721Receiver.onERC721Received.selector;
    }
}