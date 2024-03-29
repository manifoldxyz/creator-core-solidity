// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author: manifold.xyz

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155Creator compliant extension contracts.
 */
interface IERC1155CreatorMintPermissions is IERC165 {
    /**
     * @dev get approval to mint
     */
    function approveMint(
        address extension,
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;
}
