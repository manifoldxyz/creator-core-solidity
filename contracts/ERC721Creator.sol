// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "manifoldxyz-libraries-solidity/contracts/access/AdminControl.sol";
import "./ERC721CreatorCore.sol";

contract ERC721Creator is AdminControl, ERC721CreatorCore {

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorCore, AdminControl) returns (bool) {
        return ERC721CreatorCore.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Creator-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {IERC721Creator-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, baseURIIdentical);
    }


    /**
     * @dev See {IERC721Creator-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
        _unregisterExtension(extension);
    }

    /**
     * @dev See {IERC721Creator-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
        _blacklistExtension(extension);
    }

    /**
     * @dev See {IERC721Creator-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri) external override extensionRequired {
        _setBaseTokenURIExtension(uri, false);
    }

    /**
     * @dev See {IERC721Creator-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external override extensionRequired {
        _setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {IERC721Creator-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override extensionRequired {
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {IERC721Creator-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external override extensionRequired {
        _setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {IERC721Creator-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] memory tokenIds, string[] calldata uris) external override extensionRequired {
        require(tokenIds.length == uris.length, "ERC721Creator: Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURIExtension(tokenIds[i], uris[i]);            
        }
    }

    /**
     * @dev See {IERC721Creator-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        _setBaseTokenURI(uri);
    }

    /**
     * @dev See {IERC721Creator-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {IERC721Creator-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {IERC721Creator-setTokenURI}.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "ERC721Creator: Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);            
        }
    }

    /**
     * @dev See {IERC721Creator-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC721Creator-mintBase}.
     */
    function mintBase(address to) public override nonReentrant adminRequired virtual returns(uint256) {
        return _mintBase(to, "");
    }

    /**
     * @dev See {IERC721Creator-mintBase}.
     */
    function mintBase(address to, string calldata uri) public override nonReentrant adminRequired virtual returns(uint256) {
        return _mintBase(to, uri);
    }

    /**
     * @dev See {IERC721Creator-mintBaseBatch}.
     */
    function mintBaseBatch(address to, uint16 count) public override nonReentrant adminRequired virtual returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            tokenIds[i] = _mintBase(to, "");
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721Creator-mintBaseBatch}.
     */
    function mintBaseBatch(address to, string[] calldata uris) public override nonReentrant adminRequired virtual returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        for (uint i = 0; i < uris.length; i++) {
            tokenIds[i] = _mintBase(to, uris[i]);
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721Creator-mintExtension}.
     */
    function mintExtension(address to) public override nonReentrant extensionRequired virtual returns(uint256) {
        return _mintExtension(to, "");
    }

    /**
     * @dev See {IERC721Creator-mintExtension}.
     */
    function mintExtension(address to, string calldata uri) public override nonReentrant extensionRequired virtual returns(uint256) {
        return _mintExtension(to, uri);
    }

    /**
     * @dev See {IERC721Creator-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint16 count) public override nonReentrant extensionRequired virtual returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            tokenIds[i] = _mintExtension(to, "");
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721Creator-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, string[] calldata uris) public override nonReentrant extensionRequired virtual returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        for (uint i = 0; i < uris.length; i++) {
            tokenIds[i] = _mintExtension(to, uris[i]);
        }
        return tokenIds;
    }
    
}