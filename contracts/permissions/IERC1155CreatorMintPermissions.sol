// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "manifoldxyz-libraries-solidity/contracts/access/IAdminControl.sol";

/**
 * @dev Required interface of an ERC1155Creator compliant extension contracts.
 */
interface IERC1155CreatorMintPermissions is IERC165, IAdminControl {

    /**
     * @dev get approval to mint
     */
    function approveMint(address extension, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}