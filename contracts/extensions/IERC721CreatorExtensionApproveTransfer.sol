// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorExtensionBase.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC721CreatorExtensionApproveTransfer is IERC721CreatorExtensionBase {

    /**
     * @dev Set whether or not the creator will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * Approve a transfer
     */
    function approveTransfer(address creator, address from, address to, uint256 tokenId) external returns (bool);
}
