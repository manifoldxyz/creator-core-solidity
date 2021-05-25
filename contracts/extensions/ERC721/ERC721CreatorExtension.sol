// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../CreatorExtension.sol";

/**
 * @dev Base ERC721 creator extension variables
 */
abstract contract ERC721CreatorExtension is CreatorExtension {

    /**
     * @dev Legacy extension interface identifiers (see CreatorExtension for more)
     *
     * {IERC165-supportsInterface} needs to return 'true' for this interface
     * in order backwards compatible with older creator contracts
     */

    // Required to be recognized as a contract to receive onBurn for older creator contracts
    bytes4 constant internal LEGACY_ERC721_EXTENSION_BURNABLE_INTERFACE = 0xf3f4e68b;

}