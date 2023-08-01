// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseERC721CreatorTest } from "../BaseERC721CreatorTest.sol";
import {
    ERC721BurnableExtension
} from "../extensions/ERC721BurnableExtension.sol";

contract ERC721CreatorBurnsTest is BaseERC721CreatorTest {
    ERC721BurnableExtension public burnableExtension;

    modifier withBurnableExtension() {
        vm.prank(creator);
        burnableExtension = new ERC721BurnableExtension(
            creatorContractAddress
        );
        vm.prank(creator);
        creatorContract().registerExtension(
            address(burnableExtension),
            extensionTokenURI
        );
        _;
    }

    function testBurnableExtension() public withBurnableExtension {
        mintWithExtension(address(burnableExtension), alice);

        // Only the owner can burn the token
        vm.expectRevert("Caller is not owner or approved");
        creatorContract().burn(1);

        // Non-existent token can't be burned
        vm.expectRevert("ERC721: invalid token ID");
        creatorContract().burn(2);

        // Burning a token executes onBurn callback
        vm.prank(alice);
        creatorContract().burn(1);
        assertEq(burnableExtension.burntTokens(0), 1);
    }
}
