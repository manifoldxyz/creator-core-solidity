// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorExtension.sol";

/**
 * @dev Required interface of an ERC721Creator compliant extension contracts.
 */
interface IERC721CreatorExtensionMulti is IERC721CreatorExtension {
    event CreatorAdded(address indexed creator, address indexed sender);

    /**
     * @dev add a creator to this extension
     */
    function addERC721Creator(address creator) external;

    /**
     * @dev remove a creator to this extension
     */
    function removeERC721Creator(address creator) external;
}