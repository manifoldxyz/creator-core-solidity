// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorExtensionBase.sol";

/**
 * @dev Required interface of an ERC721Creator compliant extension contracts.
 */
interface IERC721CreatorExtensionBurnable is IERC721CreatorExtensionBase {
    event CreatorAdded(address indexed creator, address indexed sender);

    /**
     * @dev mint a token
     */
    function mint(address creator, address to) external returns (uint256);

    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256 tokenId) external;
}