// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

// @dev The majority of this test file was taken from Solmate with some modifications
// https://github.com/transmissions11/solmate/blob/main/src/test/ERC721.t.sol

import {MockERC721Enumerable} from "./helpers/ERC721Enumerable.sol";
import {ERC721Test} from "./ERC721.t.sol";

contract ERC721EnumerableTest is ERC721Test {
    function setUp() public override {
        token = address(new MockERC721Enumerable("Token", "TKN"));
    }
}