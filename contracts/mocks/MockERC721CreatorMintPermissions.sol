// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721CreatorMintPermissions.sol";
import "../IERC721Creator.sol";

contract MockERC721CreatorMintPermissions is ERC721CreatorMintPermissions {
    bool _approveEnabled;

    constructor(address creator_) ERC721CreatorMintPermissions (creator_) {
        _approveEnabled = true;
    }

    function setApproveEnabled(bool enabled) external {
        _approveEnabled = enabled;
    }

    function approveMint(address extension, uint256 tokenId, address to) public override {
        ERC721CreatorMintPermissions.approveMint(extension, tokenId, to);
        require(_approveEnabled, "MockERC721CreatorMintPermissions: Disabled");
    }
}
