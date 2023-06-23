// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721CreatorTest } from "./helpers/ERC721CreatorTest.sol";
import { BurnableExtension } from "./helpers/extensions/BurnableExtension.sol";

contract ERC721CreatorBurnsTest is ERC721CreatorTest {
    BurnableExtension burnableExtension;

    function setUp() public override {
        super.setUp();
        vm.prank(creator);
        burnableExtension = new BurnableExtension(address(creatorContract));
        _registerExtension(address(burnableExtension));
    }

    function testBurnableExtension() public {
        burnableExtension.mint(alice);

        // Only the owner can burn the token
        vm.expectRevert("Caller is not owner or approved");
        creatorContract.burn(1);

        // Non-existent token can't be burned
        vm.expectRevert("ERC721: invalid token ID");
        creatorContract.burn(2);

        // Burning a token executes onBurn callback
        vm.prank(alice);
        creatorContract.burn(1);
        assertEq(burnableExtension.burntTokens(0), 1);
    }
}
