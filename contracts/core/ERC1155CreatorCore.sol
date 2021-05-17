// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../extensions/IERC1155CreatorExtensionApproveTransfer.sol";
import "../extensions/IERC1155CreatorExtensionBurnable.sol";
import "../permissions/IERC1155CreatorMintPermissions.sol";
import "./IERC1155CreatorCore.sol";
import "./CreatorCore.sol";

/**
 * @dev Core ERC1155 creator implementation
 */
abstract contract ERC1155CreatorCore is CreatorCore, IERC1155CreatorCore {

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => uint256) private _tokenCounts;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC1155CreatorCore).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransferExtension}.
     */
    function setApproveTransferExtension(bool enabled) external override extensionRequired {
        require(!enabled || ERC165Checker.supportsInterface(msg.sender, type(IERC1155CreatorExtensionApproveTransfer).interfaceId), "ERC1155CreatorCore: Requires extension to implement IERC1155CreatorExtensionApproveTransfer");
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
        require(permissions == address(0x0) || ERC165Checker.supportsInterface(permissions, type(IERC1155CreatorMintPermissions).interfaceId), "ERC1155CreatorCore: Invalid address");
        if (_extensionPermissions[extension] != permissions) {
            _extensionPermissions[extension] = permissions;
            emit MintPermissionsUpdated(extension, permissions, msg.sender);
        }
    }

    /**
     * Check if an extension can mint
     */
    function _checkMintPermissions(address to, uint256[] memory tokenIds, uint256[] memory amounts) internal {
        if (_extensionPermissions[msg.sender] != address(0x0)) {
            IERC1155CreatorMintPermissions(_extensionPermissions[msg.sender]).approveMint(msg.sender, to, tokenIds, amounts);
        }
    }

    /**
     * Post mint actions
     */
    function _postMint(uint256[] memory tokenIds, uint256[] memory amounts) internal virtual {
         for (uint i = 0; i < tokenIds.length; i++) {
             _tokenCounts[tokenIds[i]] += amounts[i];
         }
    }


    /**
     * Post burn actions
     */
    function _postBurn(address owner, uint256[] memory tokenIds, uint256[] memory amounts) internal virtual {
        require(tokenIds.length > 0, "ERC1155CreatorCore: Invalid input");
        address extension = _tokensExtension[tokenIds[0]];
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_tokensExtension[tokenIds[i]] == extension, "ERC1155CreatorCore: Mismatched token originators");
            _tokenCounts[tokenIds[i]] -= amounts[i];
        }
        // Callback to originating extension if needed
        if (extension != address(this)) {
           if (ERC165Checker.supportsInterface(extension, type(IERC1155CreatorExtensionBurnable).interfaceId)) {
               IERC1155CreatorExtensionBurnable(extension).onBurn(owner, tokenIds, amounts);
           }
        }
    }

    /**
     * Approve a transfer
     */
    function _approveTransfer(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts) internal {
        require(tokenIds.length > 0, "ERC1155CreatorCore: Invalid input");
        address extension = _tokensExtension[tokenIds[0]];
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_tokensExtension[tokenIds[i]] == extension, "ERC1155CreatorCore: Mismatched token originators");
        }
        if (_extensionApproveTransfers[extension]) {
            require(IERC1155CreatorExtensionApproveTransfer(extension).approveTransfer(from, to, tokenIds, amounts), "ERC1155Creator: Extension approval failure");
        }
    }

    function _createSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

}