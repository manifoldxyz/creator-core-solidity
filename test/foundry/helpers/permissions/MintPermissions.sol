// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721CreatorMintPermissions} from "creator-core/permissions/ERC721/ERC721CreatorMintPermissions.sol";

contract MintPermissions is ERC721CreatorMintPermissions {
    bool _approveEnabled;

    constructor(address creator_) ERC721CreatorMintPermissions(creator_) {
        _approveEnabled = true;
    }

    function setApproveEnabled(bool enabled) external {
        _approveEnabled = enabled;
    }

    function approveMint(
        address extension,
        address to,
        uint256 tokenId
    ) public override {
        ERC721CreatorMintPermissions.approveMint(extension, to, tokenId);
        require(_approveEnabled, "MintPermissions: Disabled");
    }
}
