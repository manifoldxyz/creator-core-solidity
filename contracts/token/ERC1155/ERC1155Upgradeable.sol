// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC1155Core.sol";
import "openzeppelin-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-1155[ERC1155] Non-Fungible Token Standard,
 */
abstract contract ERC1155Upgradeable is Initializable, ERC1155Core {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC1155_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC1155_init_unchained(name_, symbol_);
    }

    function __ERC1155_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }
}
