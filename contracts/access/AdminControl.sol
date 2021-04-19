// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/ERC165.sol";
import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./IAdminControl.sol";

abstract contract AdminControl is Ownable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {AdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory) {
        address[] memory admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {AdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner returns (bool) {
        emit AdminApproved(admin, msg.sender);
        return _admins.add(admin);
    }

    /**
     * @dev See {AdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner returns (bool) {
        emit AdminRevoked(admin, msg.sender);
        return _admins.remove(admin);
    }

}