// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ERC721Creator.sol";
import "./ERC721CreatorCoreEnumerable.sol";

contract ERC721CreatorEnumerable is ERC721Creator, ERC721CreatorCoreEnumerable {

    constructor (string memory _name, string memory _symbol) ERC721Creator(_name, _symbol) {
    }
        
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Creator, ERC721CreatorCoreEnumerable) returns (bool) {
        return ERC721Creator.supportsInterface(interfaceId) || ERC721CreatorCoreEnumerable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721CreatorCoreEnumerable) {
        ERC721CreatorCoreEnumerable._beforeTokenTransfer(from, to, tokenId);
    }


    function _mintBase(address to, string memory uri) internal override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) virtual returns(uint256 tokenId) {
        return ERC721CreatorCoreEnumerable._mintBase(to, uri);
    }

    function _mintExtension(address to, string memory uri) internal override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) virtual returns(uint256 tokenId) {
        return ERC721CreatorCoreEnumerable._mintExtension(to, uri);
    }

    function _burn(uint256 tokenId) internal override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) virtual {
        ERC721CreatorCoreEnumerable._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) returns (string memory) {
        return ERC721CreatorCore.tokenURI(tokenId);
    }

}