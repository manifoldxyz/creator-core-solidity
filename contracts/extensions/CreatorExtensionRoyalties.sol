// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author: manifold.xyz

import {ERC165Checker} from "openzeppelin/utils/introspection/ERC165Checker.sol";
import {IERC165} from "openzeppelin/utils/introspection/ERC165.sol";
import {AdminControl} from "manifoldxyz/libraries-solidity/access/AdminControl.sol";
import {IERC721CreatorCore} from "../core/IERC721CreatorCore.sol";
import {CreatorExtension} from "./CreatorExtension.sol";
import {ICreatorExtensionRoyalties} from "./ICreatorExtensionRoyalties.sol";

/**
 * @dev Extend this implementation to have creator
 * check with it for token based royalties
 */
abstract contract CreatorExtensionRoyalties is AdminControl, CreatorExtension, ICreatorExtensionRoyalties {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, CreatorExtension, IERC165)
        returns (bool)
    {
        return interfaceId == type(ICreatorExtensionRoyalties).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorExtensionRoyalties-getRoyalties}
     */
    function getRoyalties(address creator, uint256 tokenId)
        external
        view
        virtual
        override
        returns (address payable[] memory, uint256[] memory);
}
