// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC7211155Core} from "./ERC7211155Core.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155] Non-Fungible Token Standard
 */
abstract contract ERC7211155Base is ERC7211155Core {
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
}
