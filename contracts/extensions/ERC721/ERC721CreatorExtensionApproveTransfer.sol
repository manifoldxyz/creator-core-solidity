// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "manifoldxyz-libraries-solidity/contracts/access/AdminControl.sol";

import "../../core/IERC721CreatorCore.sol";
import "./ERC721CreatorExtension.sol";
import "./IERC721CreatorExtensionApproveTransfer.sol";

/**
 * @dev Suggested implementation for extensions that require the creator to
 * check with it before a transfer occurs
 */
abstract contract ERC721CreatorExtensionApproveTransfer is ERC721CreatorExtension, AdminControl, IERC721CreatorExtensionApproveTransfer {

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == LEGACY_EXTENSION_INTERFACE
            || interfaceId == type(IERC721CreatorExtensionApproveTransfer).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorExtensionApproveTransfer-setApproveTransfer}
     */
    function setApproveTransfer(address creator, bool enabled) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtensionApproveTransfer: Requires ERC721CreatorCore");
        IERC721CreatorCore(creator).setApproveTransferExtension(enabled);
    }

}