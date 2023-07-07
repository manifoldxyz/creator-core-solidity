// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";

contract BaseCreatorTest is Test {
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address creator = address(0xC12EA7012);

    string baseTokenURI = "creator://";
    string extensionTokenURI = "extension://";

    function setUp() public virtual {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(creator, "creator");
    }

    function _uri(
        string memory uri,
        uint256 tokenId
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(uri, Strings.toString(tokenId)));
    }
}
