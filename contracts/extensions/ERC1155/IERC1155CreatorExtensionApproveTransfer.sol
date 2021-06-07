// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC1155CreatorExtensionApproveTransfer is IERC165 {

    /**
     * @dev Set whether or not the creator contract will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * @dev Called by creator contract to approve a transfer
     */
    function approveTransfer(address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external returns (bool);
}