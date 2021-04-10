// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721Creator compliant extension contracts.
 */
interface IAdminControl is IERC165 {
    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     * Returns True if newly added, False if already added.
     */
    function approveAdmin(address admin) external returns (bool);

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     * Returns True if removed, False if already removed.
     */
    function revokeAdmin(address admin) external returns (bool);

}