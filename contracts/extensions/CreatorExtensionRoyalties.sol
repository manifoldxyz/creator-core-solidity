// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../core/IERC721CreatorCore.sol";
import "./CreatorExtension.sol";
import "./ICreatorExtensionRoyalties.sol";

/**
 * @dev Extend this implementation to have creator
 * check with it for token based royalties
 */
abstract contract CreatorExtensionRoyalties is AdminControl, CreatorExtension, ICreatorExtensionRoyalties {

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionRoyalties).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorExtensionRoyalties-getRoyalties}
     */
    function getRoyalties(address creator, uint256 tokenId) external virtual view override returns (address payable[] memory, uint256[] memory);
}
