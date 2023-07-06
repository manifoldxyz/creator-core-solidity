// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC1155CreatorTest } from "./helpers/ERC1155CreatorTest.sol";
import {
    ERC1155BurnableExtension
} from "./helpers/extensions/ERC1155BurnableExtension.sol";

contract ERC1155CreatorBurnsTest is ERC1155CreatorTest {
    ERC1155BurnableExtension burnableExtension;

    function setUp() public override {
        super.setUp();
        vm.prank(creator);
        burnableExtension = new ERC1155BurnableExtension(
            address(creatorContract)
        );
        _registerExtension(address(burnableExtension));
    }

    function testBurnableExtension() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        // Only the owner can burn the token
        vm.expectRevert("Caller is not owner or approved");
        creatorContract.burn(alice, tokenIds, amounts);

        // Non-existent token can't be burned
        vm.prank(alice);
        vm.expectRevert("ERC1155: burn amount exceeds balance");
        creatorContract.burn(alice, tokenIds, amounts);

        // Burning a token executes onBurn callback
        tokenIds[0] = mintWithExtension(address(burnableExtension), alice);
        vm.prank(alice);
        creatorContract.burn(alice, tokenIds, amounts);
        assertEq(burnableExtension.burntTokens(tokenIds[0]), 1);
    }
}
