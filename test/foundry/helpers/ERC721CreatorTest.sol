// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC721Creator} from "creator-core/ERC721Creator.sol";

contract ERC721CreatorTest is Test {
    ERC721Creator creatorContract;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address creator = address(0xC12EA7012);

    function setUp() public {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(creator, "creator");
        _setUpCreatorContract();
    }

    /**
     * @dev Test helpers
     */

    function _setUpCreatorContract() private {
        vm.prank(creator);
        creatorContract = new ERC721Creator("Test", "TEST");
    }
}
