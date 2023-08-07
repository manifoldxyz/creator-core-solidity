// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author: manifold.xyz

import {ERC165} from "openzeppelin/utils/introspection/ERC165.sol";

/**
 * @dev Base creator extension variables
 */
abstract contract CreatorExtension is ERC165 {
    /**
     * @dev Legacy extension interface identifiers
     *
     * {IERC165-supportsInterface} needs to return 'true' for this interface
     * in order backwards compatible with older creator contracts
     */
    bytes4 internal constant LEGACY_EXTENSION_INTERFACE = 0x7005caad;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == LEGACY_EXTENSION_INTERFACE || super.supportsInterface(interfaceId);
    }
}
