// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../../core/IERC1155CreatorCore.sol";
import "./IERC1155CreatorExtensionApproveTransfer.sol";

/**
 * @dev Suggested implementation for extensions that require the creator to
 * check with it before a transfer occurs
 */
abstract contract ERC1155CreatorExtensionApproveTransfer is AdminControl, IERC1155CreatorExtensionApproveTransfer {

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IERC1155CreatorExtensionApproveTransfer).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155CreatorExtensionApproveTransfer-setApproveTransfer}
     */
    function setApproveTransfer(address creator, bool enabled) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC1155CreatorCore).interfaceId), "creator must implement IERC1155CreatorCore");
        IERC1155CreatorCore(creator).setApproveTransferExtension(enabled);
    }

}