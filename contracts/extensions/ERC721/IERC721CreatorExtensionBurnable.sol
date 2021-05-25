// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Your extension is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the extension created is
 * burned
 */
interface IERC721CreatorExtensionBurnable is IERC165 {
    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256 tokenId) external;
}