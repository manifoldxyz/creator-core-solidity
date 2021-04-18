// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/ERC165.sol";
import "openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";
import "./IERC721Creator.sol";
import "./IERC721CreatorMintPermissions.sol";
import "./access/AdminControl.sol";

abstract contract ERC721CreatorMintPermissions is ERC165, AdminControl, IERC721CreatorMintPermissions {
     address internal immutable _creator;

     constructor(address creator_) {
         require(ERC165Checker.supportsInterface(creator_, type(IERC721Creator).interfaceId), "Must implement IERC721Creator");
         _creator = creator_;
     }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, AdminControl) returns (bool) {
        return interfaceId == type(IERC721CreatorMintPermissions).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorMintPermissions-approveMint}.
     */
    function approveMint(address, uint256, address) public virtual override {
        require(msg.sender == _creator, "Can only be called by token creator");
    }
     


}