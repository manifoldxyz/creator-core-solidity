// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../token/ERC721/ERC721Enumerable.sol";

contract MockERC721Enumerable is ERC721Enumerable {

    constructor (string memory _name, string memory _symbol) ERC721Base(_name, _symbol) {
    }

    function testMint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId, 0);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return "";
    }
}
