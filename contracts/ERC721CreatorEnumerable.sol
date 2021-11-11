// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./ERC721Creator.sol";
import "./core/ERC721CreatorCoreEnumerable.sol";

/**
 * @dev ERC721Creator implementation (with enumerable api's)
 */
contract ERC721CreatorEnumerable is ERC721Creator, ERC721CreatorCoreEnumerable, ERC721Enumerable {

    constructor (string memory _name, string memory _symbol) ERC721Creator(_name, _symbol) {
    }
        
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Creator, ERC721CreatorCoreEnumerable, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721CreatorCoreEnumerable).interfaceId || ERC721Creator.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721Creator, ERC721CreatorCoreEnumerable) {
        _approveTransfer(from, to, tokenId);
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _postMintBase(address to, uint256 tokenId) internal virtual override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) {
        ERC721CreatorCoreEnumerable._postMintBase(to, tokenId);
    }

    function _postMintExtension(address to, uint256 tokenId) internal virtual override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) {
        ERC721CreatorCoreEnumerable._postMintExtension(to, tokenId);
    }

    function _postBurn(address owner, uint256 tokenId) internal virtual override(ERC721CreatorCore, ERC721CreatorCoreEnumerable) {
        ERC721CreatorCoreEnumerable._postBurn(owner, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Creator, ERC721) returns (string memory) {
        return ERC721Creator.tokenURI(tokenId);
    }

}