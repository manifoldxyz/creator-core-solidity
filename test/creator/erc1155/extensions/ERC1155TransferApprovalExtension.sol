// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155CreatorCore } from "creator-core/core/IERC1155CreatorCore.sol";
import {
    ERC1155CreatorExtensionApproveTransfer
} from "creator-core/extensions/ERC1155/ERC1155CreatorExtensionApproveTransfer.sol";
import { ERC1155Extension } from "./ERC1155Extension.sol";

contract ERC1155TransferApprovalExtension is
    ERC1155CreatorExtensionApproveTransfer,
    ERC1155Extension
{
    bool _approveEnabled;

    constructor(address creator) ERC1155Extension(creator) {}

    function setApproveEnabled(bool enabled) public {
        _approveEnabled = enabled;
    }

    function approveTransfer(
        address,
        address,
        address,
        uint256[] calldata,
        uint256[] calldata
    ) external view virtual override returns (bool) {
        return _approveEnabled;
    }
}
