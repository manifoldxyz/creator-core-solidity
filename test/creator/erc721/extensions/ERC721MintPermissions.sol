// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC721CreatorMintPermissions} from "creator-core/permissions/ERC721/IERC721CreatorMintPermissions.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";

contract ERC721MintPermissions is IERC721CreatorMintPermissions {
    address _creator;
    bool _approveEnabled;

    constructor(address creator) {
        _creator = creator;
        _approveEnabled = true;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC721CreatorMintPermissions).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function setApproveEnabled(bool enabled) external {
        _approveEnabled = enabled;
    }

    function approveMint(address, address, uint256) public view override {
        require(_approveEnabled, "MintPermissions: Disabled");
    }
}
