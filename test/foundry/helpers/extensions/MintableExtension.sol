// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721CreatorCore} from "creator-core/core/IERC721CreatorCore.sol";

interface IMintableExtension {
    function mint(address to) external returns (uint256);

    function mint(address to, string calldata uri) external returns (uint256);
}

contract MintableExtension {
    address _creator;

    constructor(address creator) {
        _creator = creator;
    }

    function mint(address to) external returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

    function mint(address to, string calldata uri) external returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to, uri);
    }
}
