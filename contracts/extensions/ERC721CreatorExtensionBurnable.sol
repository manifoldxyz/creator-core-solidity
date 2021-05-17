// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../core/IERC721CreatorCore.sol";
import "./IERC721CreatorExtensionBurnable.sol";
import "./CreatorExtensionBase.sol";

/**
 * @dev Suggested implementation for extensions that want to receive onBurn callbacks
 * Mint tracks the creators/tokens created, and onBurn only accepts callbacks from
 * the creator of a token created.
 */
abstract contract ERC721CreatorExtensionBurnable is CreatorExtensionBase, IERC721CreatorExtensionBurnable {

    mapping (uint256 => address) private _tokenCreators;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtensionBase, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionBurnable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorExtensionBurnable-mint}.
     */
    function mint(address creator, address to) external override adminRequired returns (uint256) {
        return _mint(creator, to);
    }

    /**
     * @dev See {IERC721CreatorExtensionBurnable-mintBatch}.
     */
    function mintBatch(address creator, address to, uint16 count) external override adminRequired returns (uint256[] memory) {
        return _mintBatch(creator, to, count);
    }

    function _mint(address creator, address to) internal returns (uint256) {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtensionBurnable: Requires ERC721CreatorCore");
        uint256 tokenId = IERC721CreatorCore(creator).mintExtension(to);
        _tokenCreators[tokenId] = creator;
        return tokenId;
    }

    function _mint(address creator, address to, string memory uri) internal returns (uint256) {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtensionBurnable: Requires ERC721CreatorCore");
        uint256 tokenId = IERC721CreatorCore(creator).mintExtension(to, uri);
        _tokenCreators[tokenId] = creator;
        return tokenId;
    }

    function _mintBatch(address creator, address to, uint16 count) internal returns (uint256[] memory tokenIds) {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtensionBurnable: Requires ERC721CreatorCore");
        tokenIds = IERC721CreatorCore(creator).mintExtensionBatch(to, count);
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _tokenCreators[tokenIds[i]] = creator;
        }
        return tokenIds;
    }

    function _mintBatch(address creator, address to, string[] memory uris) internal returns (uint256[] memory tokenIds) {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtensionBurnable: Requires ERC721CreatorCore");
        tokenIds = IERC721CreatorCore(creator).mintExtensionBatch(to, uris);
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _tokenCreators[tokenIds[i]] = creator;
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721CreatorExtension-onBurn}.
     */
    function onBurn(address, uint256 tokenId) public virtual override {
        require(_tokenCreators[tokenId] == msg.sender, "ERC721CreatorExtensionBurnable: Can only be called by token creator");
    }


}