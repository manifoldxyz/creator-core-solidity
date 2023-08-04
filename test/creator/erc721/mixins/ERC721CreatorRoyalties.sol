// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {BaseERC721CreatorTest} from "../BaseERC721CreatorTest.sol";
import {ERC721RoyaltiesExtension} from "../extensions/ERC721RoyaltiesExtension.sol";

contract ERC721CreatorRoyaltiesTest is BaseERC721CreatorTest {
    ERC721RoyaltiesExtension public royaltiesExtension;

    modifier withRoyaltiesExtension() {
        vm.prank(creator);
        royaltiesExtension = new ERC721RoyaltiesExtension(
            creatorContractAddress
        );
        vm.prank(creator);
        creatorContract().registerExtension(address(royaltiesExtension), extensionTokenURI);
        _;
    }

    function testRoyaltiesNonExistentToken() public withRoyaltiesExtension {
        vm.expectRevert("Nonexistent token");
        creatorContract().getRoyalties(1);

        vm.prank(creator);
        vm.expectRevert("Nonexistent token");
        creatorContract().setRoyalties(1, new address payable[](0), new uint256[](0));
    }

    function testRoyaltiesInvalidInput() public withRoyaltiesExtension {
        uint256 tokenId = mintWithCreator(alice);

        // No royalties currently set
        assertRoyalties(1, new address payable[](0), new uint256[](0));

        address payable[] memory recipients = new address payable[](2);
        uint256[] memory values = new uint256[](2);
        recipients[0] = payable(alice);
        recipients[1] = payable(bob);
        values[0] = 9999;
        values[1] = 1;

        // Revert on invalid total royalties
        vm.prank(creator);
        vm.expectRevert("Invalid total royalties");
        creatorContract().setRoyalties(tokenId, recipients, values);

        // Revert on invalid recipients input
        address payable[] memory invalidRecipients = new address payable[](1);
        invalidRecipients[0] = payable(alice);

        vm.prank(creator);
        vm.expectRevert("Invalid input");
        creatorContract().setRoyalties(tokenId, invalidRecipients, values);

        // Revert on invalid values input
        uint256[] memory invalidValues = new uint256[](1);
        invalidValues[0] = 1000;

        vm.prank(creator);
        vm.expectRevert("Invalid input");
        creatorContract().setRoyalties(tokenId, recipients, invalidValues);
    }

    function testRoyaltiesSetViaCreator() public withRoyaltiesExtension {
        // Mint a token
        uint256 tokenId = mintWithCreator(alice);

        // Setup royalty data
        address payable[] memory recipients = new address payable[](2);
        uint256[] memory values = new uint256[](2);
        recipients[0] = payable(alice);
        recipients[1] = payable(bob);
        values[0] = 1000;
        values[1] = 1000;

        // Update royalty info on contract
        vm.prank(creator);
        creatorContract().setRoyalties(tokenId, recipients, values);
        assertRoyalties(tokenId, recipients, values);

        // Sdditional mints don't use token royalties
        tokenId = mintWithCreator(alice);
        assertRoyalties(tokenId, new address payable[](0), new uint256[](0));

        // Default royalties can apply to all other tokens
        vm.prank(creator);
        creatorContract().setRoyalties(recipients, values);
        assertRoyalties(tokenId, recipients, values);

        // Default royalties apply to new tokens
        assertRoyalties(mintWithCreator(alice), recipients, values);

        // Default royalties can be removed
        vm.prank(creator);
        creatorContract().setRoyalties(new address payable[](0), new uint256[](0));
        assertRoyalties(tokenId, new address payable[](0), new uint256[](0));

        // New tokens have no royalties if there is no default
        assertRoyalties(mintWithCreator(alice), new address payable[](0), new uint256[](0));
    }

    function testRoyaltiesSetViaExtension() public withRoyaltiesExtension {
        // Mint a token
        uint256 tokenId = mintWithExtension(address(royaltiesExtension), alice);

        // Setup royalty data
        address payable[] memory recipients = new address payable[](1);
        uint256[] memory values = new uint256[](1);
        recipients[0] = payable(creator);
        values[0] = 1000;

        // Update royalty info for extension
        vm.prank(creator);
        creatorContract().setRoyaltiesExtension(address(royaltiesExtension), recipients, values);
        assertRoyalties(tokenId, recipients, values);

        // Contract mints don't use extension royalties
        assertRoyalties(mintWithCreator(alice), new address payable[](0), new uint256[](0));

        // Minting another extension token uses the extension royalties
        assertRoyalties(mintWithExtension(address(royaltiesExtension), alice), recipients, values);

        // Extension royalties can be removed
        vm.prank(creator);
        creatorContract().setRoyaltiesExtension(address(royaltiesExtension), new address payable[](0), new uint256[](0));
        assertRoyalties(tokenId, new address payable[](0), new uint256[](0));

        // New tokens have no royalties if there is no default
        assertRoyalties(
            mintWithExtension(address(royaltiesExtension), alice), new address payable[](0), new uint256[](0)
        );
    }

    function testRoyaltiesExtensionPriority() public withRoyaltiesExtension {
        // This test enforces the royalty priority (highest to lowest)
        // 1. token
        // 2. extension override
        // 3. extension default
        // 4. creator default

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
        creatorContract().setRoyalties(recipients, values);
        assertRoyalties(1, recipients, values);
        assertRoyalties(2, recipients, values);

        // Set default royalties for extension
        uint256[] memory overrideValues = new uint256[](1);
        overrideValues[0] = 2000;

        vm.prank(creator);
        creatorContract().setRoyaltiesExtension(address(royaltiesExtension), recipients, overrideValues);
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
        creatorContract().setRoyalties(1, recipients, overrideValues);
        assertRoyalties(1, recipients, overrideValues);
        assertRoyalties(2, recipients, values);
    }

    function assertRoyalties(
        uint256 tokenId,
        address payable[] memory expectedRecipients,
        uint256[] memory expectedValues
    ) public {
        (address payable[] memory getRoyaltiesRecipients, uint256[] memory getRoyaltiesValues) =
            creatorContract().getRoyalties(tokenId);

        (address payable[] memory getFeesRecipients, uint256[] memory getFeesValues) =
            creatorContract().getFees(tokenId);

        address payable[] memory feeRecipients = creatorContract().getFeeRecipients(tokenId);

        uint256[] memory feeBps = creatorContract().getFeeBps(tokenId);

        if (
            expectedRecipients.length != getRoyaltiesRecipients.length
                || expectedValues.length != getRoyaltiesValues.length
                || expectedRecipients.length != getFeesRecipients.length || expectedValues.length != getFeesValues.length
                || expectedRecipients.length != feeRecipients.length || expectedValues.length != feeBps.length
        ) {
            fail();
        }

        for (uint256 i = 0; i < expectedRecipients.length; i++) {
            assertEq(getRoyaltiesRecipients[i], expectedRecipients[i]);
            assertEq(getRoyaltiesValues[i], expectedValues[i]);
            assertEq(getFeesRecipients[i], expectedRecipients[i]);
            assertEq(getFeesValues[i], expectedValues[i]);
            assertEq(feeRecipients[i], expectedRecipients[i]);
            assertEq(feeBps[i], expectedValues[i]);
        }

        // Reverts if more than one recipient when using EIP-2981
        uint256 value = 10000000000;
        if (expectedRecipients.length == 1) {
            (, uint256 royaltyValue) = creatorContract().royaltyInfo(tokenId, value);
            assertEq(royaltyValue, (value * expectedValues[0]) / 10000);
        } else if (expectedRecipients.length > 1) {
            vm.expectRevert("More than 1 royalty receiver");
            creatorContract().royaltyInfo(tokenId, value);
        }
    }
}
