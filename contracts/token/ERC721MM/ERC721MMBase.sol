// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC721MMCore} from "./ERC721MMCore.sol";

/**
 * @dev Implementation of Non-Fungible Token Standard and Multi-Token Standard
 * https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard
 * https://eips.ethereum.org/EIPS/eip-1155[ERC1155] Multi-Token Standard
 */
abstract contract ERC721MMBase is ERC721MMCore {
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
}
