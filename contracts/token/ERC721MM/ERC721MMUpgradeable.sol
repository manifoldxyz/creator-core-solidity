// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC721MMCore} from "./ERC721MMCore.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of Non-Fungible Token Standard and Multi-Token Standard
 * https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard
 * https://eips.ethereum.org/EIPS/eip-1155[ERC1155] Multi-Token Standard
 */
abstract contract ERC721MMUpgradeable is Initializable, ERC721MMCore {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721MM_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721MM_init_unchained(name_, symbol_);
    }

    function __ERC721MM_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
}
