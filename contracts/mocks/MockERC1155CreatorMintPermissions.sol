// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../permissions/ERC1155/ERC1155CreatorMintPermissions.sol";

contract MockERC1155CreatorMintPermissions is ERC1155CreatorMintPermissions {
    bool _approveEnabled;

    constructor(address creator_) ERC1155CreatorMintPermissions (creator_) {
        _approveEnabled = true;
    }

    function setApproveEnabled(bool enabled) external {
        _approveEnabled = enabled;
    }

    function approveMint(address extension, address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) public override {
        ERC1155CreatorMintPermissions.approveMint(extension, to, tokenIds, amounts);
        require(_approveEnabled, "MockERC1155CreatorMintPermissions: Disabled");
    }
}
