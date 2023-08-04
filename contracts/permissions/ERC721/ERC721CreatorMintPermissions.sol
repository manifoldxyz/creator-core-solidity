// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin/utils/introspection/ERC165.sol";
import "openzeppelin/utils/introspection/ERC165Checker.sol";
import "manifoldxyz/libraries-solidity/access/AdminControl.sol";
import "../../core/IERC721CreatorCore.sol";
import "./IERC721CreatorMintPermissions.sol";

/**
 * @dev Basic implementation of a permission contract that works with a singular creator contract.
 * approveMint requires the sender to be the configured creator.
 */
abstract contract ERC721CreatorMintPermissions is ERC165, AdminControl, IERC721CreatorMintPermissions {
    address internal immutable _creator;

    constructor(address creator_) {
        require(
            ERC165Checker.supportsInterface(creator_, type(IERC721CreatorCore).interfaceId),
            "Must implement IERC721CreatorCore"
        );
        _creator = creator_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165, AdminControl)
        returns (bool)
    {
        return interfaceId == type(IERC721CreatorMintPermissions).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorMintPermissions-approveMint}.
     */
    function approveMint(address, address, uint256) public virtual override {
        require(msg.sender == _creator, "Can only be called by token creator");
    }
}
