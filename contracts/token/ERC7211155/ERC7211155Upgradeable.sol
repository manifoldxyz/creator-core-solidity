// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC7211155Core} from "./ERC7211155Core.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of Non-Fungible Token Standard and Multi-Token Standard
 * https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard
 * https://eips.ethereum.org/EIPS/eip-1155[ERC1155] Multi-Token Standard
 */
abstract contract ERC7211155Upgradeable is Initializable, ERC7211155Core {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC7211155_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC7211155_init_unchained(name_, symbol_);
    }

    function __ERC7211155_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
}
