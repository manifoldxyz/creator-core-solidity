// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorExtensionBase.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC1155CreatorExtensionApproveTransfer is ICreatorExtensionBase {

    /**
     * @dev Set whether or not the creator will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * Approve a transfer
     */
    function approveTransfer(address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external returns (bool);
}
