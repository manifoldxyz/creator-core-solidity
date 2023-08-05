// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

// @dev The majority of this test file was taken from Solmate with some modifications
// https://github.com/transmissions11/solmate/blob/main/src/test/ERC721.t.sol

import {MockERC721Enumerable} from "./helpers/ERC721Enumerable.sol";
import {ERC721Test, ERC721Recipient} from "./ERC721.t.sol";
import {Test} from "forge-std/Test.sol";

contract ERC721EnumerableTest is ERC721Test {
    function setUp() public override {
        token = address(new MockERC721Enumerable("Token", "TKN"));
    }
}

contract ERC721EnumerableFunctionalityTest is Test, ERC721Recipient {
    MockERC721Enumerable public token;

    function setUp() public {
        token = new MockERC721Enumerable("Token", "TKN");
    }

    function testSupportsInterface() public {
        assertTrue(token.supportsInterface(0x780e9d63)); // ERC-721 Enumerable
    }

    function testTotalSupply() public {
        assertEq(token.totalSupply(), 0);

        token.mint(address(this), 1);
        assertEq(token.totalSupply(), 1);

        token.mint(address(this), 2);
        assertEq(token.totalSupply(), 2);
    }

    function testTokenOfOwnerByIndex() public {
        token.mint(address(this), 1);
        token.mint(address(this), 2);

        assertEq(token.tokenOfOwnerByIndex(address(this), 0), 1);
        assertEq(token.tokenOfOwnerByIndex(address(this), 1), 2);
    }

    function testTokenOfOwnerByIndexRevertsOutOfBounds() public {
        vm.expectRevert("ERC721Enumerable: owner index out of bounds");
        token.tokenOfOwnerByIndex(address(this), 0);

        token.mint(address(this), 1);

        vm.expectRevert("ERC721Enumerable: owner index out of bounds");
        token.tokenOfOwnerByIndex(address(this), 1);
    }

    function testTokenOfOwnerByIndexUpdatesAfterTransfer() public {
        token.mint(address(this), 1);
        token.mint(address(this), 2);

        assertEq(token.tokenOfOwnerByIndex(address(this), 0), 1);
        assertEq(token.tokenOfOwnerByIndex(address(this), 1), 2);

        token.transferFrom(address(this), address(0xdead), 1);
        token.transferFrom(address(this), address(0xdead), 2);

        vm.expectRevert("ERC721Enumerable: owner index out of bounds");
        token.tokenOfOwnerByIndex(address(this), 0);

        vm.expectRevert("ERC721Enumerable: owner index out of bounds");
        token.tokenOfOwnerByIndex(address(this), 1);

        assertEq(token.tokenOfOwnerByIndex(address(0xdead), 0), 1);
        assertEq(token.tokenOfOwnerByIndex(address(0xdead), 1), 2);
    }

    function testTokenByIndex() public {
        token.mint(address(this), 1);
        token.mint(address(this), 2);

        assertEq(token.tokenByIndex(0), 1);
        assertEq(token.tokenByIndex(1), 2);
    }

    function testTokenByIndexRevertsOutOfBounds() public {
        vm.expectRevert("ERC721Enumerable: global index out of bounds");
        token.tokenByIndex(0);

        token.mint(address(this), 1);

        vm.expectRevert("ERC721Enumerable: global index out of bounds");
        token.tokenByIndex(1);
    }

    function testTokenByIndexHandlesBurns() public {
        token.mint(address(this), 1);
        token.mint(address(this), 2);

        assertEq(token.tokenByIndex(0), 1);
        assertEq(token.tokenByIndex(1), 2);

        token.burn(1);

        vm.expectRevert("ERC721Enumerable: global index out of bounds");
        token.tokenByIndex(1);

        assertEq(token.tokenByIndex(0), 2);

        token.mint(address(this), 1);

        assertEq(token.tokenByIndex(0), 2);
        assertEq(token.tokenByIndex(1), 1);
    }

    function testMintRevertsNullAddress() public {
        vm.expectRevert("ERC721: mint to the zero address");
        token.mint(address(0), 1);
    }
}
