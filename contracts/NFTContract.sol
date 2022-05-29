// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NFTGenerator is ERC721, Ownable  {
    constructor() ERC721("NFT Generator", "NFTG") {
        supply = 0;
    }

    uint public supply;
    
    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
        supply++;
    }

    function safeMintNextId() public {
        _safeMint(msg.sender, supply);
        supply++;
    }

    function getSupply() public view returns(uint) {
        return supply;
    }
}
