// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC1155CreatorCore} from "creator-core/core/IERC1155CreatorCore.sol";

interface IERC1155Extension {
    function mint(address[] memory tos, uint256[] memory amounts, string[] memory uris)
        external
        returns (uint256[] memory);

    function mintExisting(address[] memory tos, uint256[] memory tokenIds, uint256[] memory amounts) external;
}

contract ERC1155Extension is IERC1155Extension {
    address _creator;

    constructor(address creator) {
        _creator = creator;
    }

    function mint(address[] memory tos, uint256[] memory amounts, string[] memory uris)
        public
        virtual
        returns (uint256[] memory)
    {
        return IERC1155CreatorCore(_creator).mintExtensionNew(tos, amounts, uris);
    }

    function mintExisting(address[] memory tos, uint256[] memory tokenIds, uint256[] memory amounts) public virtual {
        IERC1155CreatorCore(_creator).mintExtensionExisting(tos, tokenIds, amounts);
    }
}
