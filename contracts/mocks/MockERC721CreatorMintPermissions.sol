// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../permissions/ERC721/ERC721CreatorMintPermissions.sol";

contract MockERC721CreatorMintPermissions is ERC721CreatorMintPermissions {
    bool _approveEnabled;

    constructor(address creator_) ERC721CreatorMintPermissions (creator_) {
        _approveEnabled = true;
    }

    function setApproveEnabled(bool enabled) external {
        _approveEnabled = enabled;
    }

    function approveMint(address extension, address to, uint256 tokenId) public override {
        ERC721CreatorMintPermissions.approveMint(extension, to, tokenId);
        require(_approveEnabled, "MockERC721CreatorMintPermissions: Disabled");
    }
}
