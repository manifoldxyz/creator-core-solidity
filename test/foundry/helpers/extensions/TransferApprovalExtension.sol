// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721CreatorCore } from "creator-core/core/IERC721CreatorCore.sol";
import {
    ERC721CreatorExtensionApproveTransfer
} from "creator-core/extensions/ERC721/ERC721CreatorExtensionApproveTransfer.sol";
import { Extension } from "./Extension.sol";

contract TransferApprovalExtension is
    ERC721CreatorExtensionApproveTransfer,
    Extension
{
    bool _approveEnabled;

    constructor(address creator) Extension(creator) {}

    function setApproveEnabled(bool enabled) public {
        _approveEnabled = enabled;
    }

    function approveTransfer(
        address,
        address,
        address,
        uint256
    ) external view virtual override returns (bool) {
        return _approveEnabled;
    }
}
