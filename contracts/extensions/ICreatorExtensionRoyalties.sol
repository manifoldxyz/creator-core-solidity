// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author: manifold.xyz

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable royalties
 */
interface ICreatorExtensionRoyalties is IERC165 {
    /**
     * Get the royalties for a given creator/tokenId
     */
    function getRoyalties(address creator, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}
