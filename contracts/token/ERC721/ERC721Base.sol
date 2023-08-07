// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC721Core} from "./ERC721Core.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard
 */
abstract contract ERC721Base is ERC721Core {
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
}
