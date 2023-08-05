// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author: manifold.xyz

import {ERC721Base} from "creator-core/token/ERC721/ERC721Base.sol";

contract MockERC721 is ERC721Base {
    constructor(string memory _name, string memory _symbol) ERC721Base(_name, _symbol) {}

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId, 0);
    }

    function mint(address to, uint256 tokenId, bytes memory data) external {
        _safeMint(to, tokenId, 0, data);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return "";
    }
}
