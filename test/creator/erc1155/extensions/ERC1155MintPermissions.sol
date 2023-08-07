// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC1155CreatorMintPermissions} from "creator-core/permissions/ERC1155/IERC1155CreatorMintPermissions.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";

contract ERC1155MintPermissions is IERC1155CreatorMintPermissions {
    address _creator;
    bool _approveEnabled;

    constructor(address creator) {
        _creator = creator;
        _approveEnabled = true;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC1155CreatorMintPermissions).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function setApproveEnabled(bool enabled) external {
        _approveEnabled = enabled;
    }

    function approveMint(address, address[] calldata, uint256[] calldata, uint256[] calldata) public view override {
        require(_approveEnabled, "MintPermissions: Disabled");
    }
}
