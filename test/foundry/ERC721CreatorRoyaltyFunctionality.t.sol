// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721CreatorTest} from "./helpers/ERC721CreatorTest.sol";
import {RoyaltiesExtension, RoyaltyInfo} from "./helpers/extensions/RoyaltiesExtension.sol";

contract ERC721CreatorRoyaltyFunctionalityTest is ERC721CreatorTest {
    RoyaltiesExtension royaltiesExtension;

    function setUp() public override {
        super.setUp();
        vm.prank(creator);
        royaltiesExtension = new RoyaltiesExtension(address(creatorContract));
        _registerExtension(address(royaltiesExtension));
    }

    function testRoyaltiesExtension() public {
        // Mint extension token
        mintWithExtension(address(royaltiesExtension), alice);

        // Mint base token
        mintWithCreator(bob);

        // No royalties currently set
        assertRoyalties(1, new address payable[](0), new uint256[](0));
        assertRoyalties(2, new address payable[](0), new uint256[](0));

        // Set default royalties
        address payable[] memory recipients = new address payable[](1);
        uint256[] memory values = new uint256[](1);
        recipients[0] = payable(creator);
        values[0] = 1000;

        vm.prank(creator);
        creatorContract.setRoyalties(recipients, values);
        assertRoyalties(1, recipients, values);
        assertRoyalties(2, recipients, values);

        // Set default royalties for extension
        uint256[] memory overrideValues = new uint256[](1);
        overrideValues[0] = 2000;

        vm.prank(creator);
        creatorContract.setRoyaltiesExtension(
            address(royaltiesExtension),
            recipients,
            overrideValues
        );
        assertRoyalties(1, recipients, overrideValues);
        assertRoyalties(2, recipients, values);

        // Set extension overrides for a specific token
        overrideValues[0] = 3000;

        vm.prank(creator);
        royaltiesExtension.setRoyaltyOverrides(1, recipients, overrideValues);
        assertRoyalties(1, recipients, overrideValues);
        assertRoyalties(2, recipients, values);

        // Set creator contract overrides for a specific token
        overrideValues[0] = 4000;

        vm.prank(creator);
        creatorContract.setRoyalties(1, recipients, overrideValues);
        assertRoyalties(1, recipients, overrideValues);
        assertRoyalties(2, recipients, values);
    }

    function assertRoyalties(
        uint256 tokenId,
        address payable[] memory expectedRecipients,
        uint256[] memory expectedValues
    ) private {
        (
            address payable[] memory recipients,
            uint256[] memory values
        ) = creatorContract.getRoyalties(tokenId);

        if (
            expectedRecipients.length != recipients.length ||
            expectedValues.length != values.length
        ) {
            fail();
        }

        for (uint256 i = 0; i < recipients.length; i++) {
            assertEq(recipients[i], expectedRecipients[i]);
            assertEq(values[i], expectedValues[i]);
        }
    }
}
