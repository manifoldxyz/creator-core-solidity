// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721CreatorCore} from "creator-core/core/IERC721CreatorCore.sol";
import {CreatorExtensionRoyalties} from "creator-core/extensions/CreatorExtensionRoyalties.sol";
import {Extension} from "./Extension.sol";

struct RoyaltyInfo {
    address payable[] recipients;
    uint256[] values;
}

contract RoyaltiesExtension is CreatorExtensionRoyalties, Extension {
    mapping(uint256 => RoyaltyInfo) _royaltyInfo;

    constructor(address creator) Extension(creator) {}

    function setRoyaltyOverrides(
        uint256 tokenId,
        address payable[] memory receivers,
        uint256[] memory values
    ) public {
        _royaltyInfo[tokenId] = RoyaltyInfo(receivers, values);
    }

    function getRoyalties(
        address creator,
        uint256 tokenId
    )
        external
        view
        override
        returns (address payable[] memory, uint256[] memory)
    {
        require(creator == _creator, "Invalid");

        if (_royaltyInfo[tokenId].recipients.length > 0) {
            RoyaltyInfo memory info = _royaltyInfo[tokenId];
            return (info.recipients, info.values);
        } else {
            return (new address payable[](0), new uint256[](0));
        }
    }
}
