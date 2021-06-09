// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../extensions/ERC721/IERC721CreatorExtensionApproveTransfer.sol";
import "../extensions/ERC721/IERC721CreatorExtensionBurnable.sol";
import "../permissions/ERC721/IERC721CreatorMintPermissions.sol";
import "./IERC721CreatorCore.sol";
import "./CreatorCore.sol";

/**
 * @dev Core ERC721 creator implementation
 */
abstract contract ERC721CreatorCore is CreatorCore, IERC721CreatorCore {

    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorCore).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransferExtension}.
     */
    function setApproveTransferExtension(bool enabled) external override extensionRequired {
        require(!enabled || ERC165Checker.supportsInterface(msg.sender, type(IERC721CreatorExtensionApproveTransfer).interfaceId), "Extension must implement IERC721CreatorExtensionApproveTransfer");
        if (_extensionApproveTransfers[msg.sender] != enabled) {
            _extensionApproveTransfers[msg.sender] = enabled;
            emit ExtensionApproveTransferUpdated(msg.sender, enabled);
        }
    }

    /**
     * @dev Set mint permissions for an extension
     */
    function _setMintPermissions(address extension, address permissions) internal {
        require(_extensions.contains(extension), "CreatorCore: Invalid extension");
        require(permissions == address(0x0) || ERC165Checker.supportsInterface(permissions, type(IERC721CreatorMintPermissions).interfaceId), "Invalid address");
        if (_extensionPermissions[extension] != permissions) {
            _extensionPermissions[extension] = permissions;
            emit MintPermissionsUpdated(extension, permissions, msg.sender);
        }
    }

    /**
     * Check if an extension can mint
     */
    function _checkMintPermissions(address to, uint256 tokenId) internal {
        if (_extensionPermissions[msg.sender] != address(0x0)) {
            IERC721CreatorMintPermissions(_extensionPermissions[msg.sender]).approveMint(msg.sender, to, tokenId);
        }
    }

    /**
     * Override for post mint actions
     */
    function _postMintBase(address, uint256) internal virtual {}

    
    /**
     * Override for post mint actions
     */
    function _postMintExtension(address, uint256) internal virtual {}

    /**
     * Post-burning callback and metadata cleanup
     */
    function _postBurn(address owner, uint256 tokenId) internal virtual {
        // Callback to originating extension if needed
        if (_tokensExtension[tokenId] != address(this)) {
           if (ERC165Checker.supportsInterface(_tokensExtension[tokenId], type(IERC721CreatorExtensionBurnable).interfaceId)) {
               IERC721CreatorExtensionBurnable(_tokensExtension[tokenId]).onBurn(owner, tokenId);
           }
        }
        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }    
        // Delete token origin extension tracking
        delete _tokensExtension[tokenId];    
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(address from, address to, uint256 tokenId) internal {
       if (_extensionApproveTransfers[_tokensExtension[tokenId]]) {
           require(IERC721CreatorExtensionApproveTransfer(_tokensExtension[tokenId]).approveTransfer(from, to, tokenId), "ERC721Creator: Extension approval failure");
       }
    }

}