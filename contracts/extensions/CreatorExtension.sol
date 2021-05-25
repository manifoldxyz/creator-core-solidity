// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Base creator extension variables
 */
abstract contract CreatorExtension {

    /**
     * @dev Legacy extension interface identifiers
     * Needed to be backwards compatible with older creator contracts
     */
    bytes4 constant internal LEGACY_EXTENSION_INTERFACE = 0x7005caad;
}