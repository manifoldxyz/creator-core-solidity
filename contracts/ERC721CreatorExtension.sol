// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/ERC165.sol";
import "./IERC721CreatorExtension.sol";
import "./access/AdminControl.sol";

abstract contract ERC721CreatorExtension is ERC165, AdminControl, IERC721CreatorExtension {
     address internal immutable _creator;

     constructor(address creator_) {
         _creator = creator_;
     }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, AdminControl) returns (bool) {
        return interfaceId == type(IERC721CreatorExtension).interfaceId
            || super.supportsInterface(interfaceId);
    }

}