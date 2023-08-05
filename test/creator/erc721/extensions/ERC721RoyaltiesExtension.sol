// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC721CreatorCore} from "creator-core/core/IERC721CreatorCore.sol";
import {ICreatorExtensionRoyalties} from "creator-core/extensions/ICreatorExtensionRoyalties.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {ERC721Extension} from "./ERC721Extension.sol";

struct RoyaltyInfo {
    address payable[] recipients;
    uint256[] values;
}

contract ERC721RoyaltiesExtension is ICreatorExtensionRoyalties, ERC721Extension {
    mapping(uint256 => RoyaltyInfo) _royaltyInfo;

    constructor(address creator) ERC721Extension(creator) {}

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(ICreatorExtensionRoyalties).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function setRoyaltyOverrides(uint256 tokenId, address payable[] memory receivers, uint256[] memory values) public {
        _royaltyInfo[tokenId] = RoyaltyInfo(receivers, values);
    }

    function getRoyalties(address creator, uint256 tokenId)
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
