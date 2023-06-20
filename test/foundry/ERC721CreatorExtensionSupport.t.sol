// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721CreatorTest} from "./helpers/ERC721CreatorTest.sol";
import {TransferApprovalExtension} from "./helpers/extensions/TransferApprovalExtension.sol";
import {TokenURIExtension} from "./helpers/extensions/TokenURIExtension.sol";
import {RoyaltiesExtension, RoyaltyInfo} from "./helpers/extensions/RoyaltiesExtension.sol";
import {BurnableExtension} from "./helpers/extensions/BurnableExtension.sol";

contract ERC721CreatorExtensionSupportTest is ERC721CreatorTest {
    function testTransferApprovalExtension()
        public
        withTransferApprovalExtension
    {
        // Mints bypass approvals
        transferApprovalExtension.mint(alice);

        // Transfer lock transferApprovalExtension is enabled by default
        vm.prank(alice);
        vm.expectRevert("Extension approval failure");
        creatorContract.safeTransferFrom(alice, bob, 1);

        // User can't modify transfer lock transferApprovalExtension
        vm.prank(alice);
        vm.expectRevert("AdminControl: Must be owner or admin");
        transferApprovalExtension.setApproveTransfer(
            address(creatorContract),
            false
        );

        // Creator can disable transfer lock transferApprovalExtension
        vm.prank(creator);
        transferApprovalExtension.setApproveTransfer(
            address(creatorContract),
            false
        );

        // Transfer lock transferApprovalExtension is disabled
        vm.prank(alice);
        creatorContract.safeTransferFrom(alice, bob, 1);

        // Creator can re-enable transfer lock transferApprovalExtension
        vm.prank(creator);
        transferApprovalExtension.setApproveTransfer(
            address(creatorContract),
            true
        );

        // Extension logic itself disables transfers
        vm.prank(bob);
        vm.expectRevert("Extension approval failure");
        creatorContract.safeTransferFrom(bob, alice, 1);

        // Creator can enable transfers in transferApprovalExtension logic
        vm.prank(creator);
        transferApprovalExtension.setApproveEnabled(true);

        // Successful transfer
        vm.prank(bob);
        creatorContract.safeTransferFrom(bob, alice, 1);
    }

    function testRoyaltiesExtension() public withRoyaltiesExtension {
        // Mint extension token
        royaltiesExtension.mint(alice);

        // Mint base token
        vm.prank(creator);
        creatorContract.mintBase(bob);

        // No royalties currently set
        _assertRoyalties(1, new address payable[](0), new uint256[](0));
        _assertRoyalties(2, new address payable[](0), new uint256[](0));

        // Set default royalties
        address payable[] memory recipients = new address payable[](1);
        uint256[] memory values = new uint256[](1);
        recipients[0] = payable(creator);
        values[0] = 1000;

        vm.prank(creator);
        creatorContract.setRoyalties(recipients, values);
        _assertRoyalties(1, recipients, values);
        _assertRoyalties(2, recipients, values);

        // Set default royalties for extension
        uint256[] memory overrideValues = new uint256[](1);
        overrideValues[0] = 2000;

        vm.prank(creator);
        creatorContract.setRoyaltiesExtension(
            address(royaltiesExtension),
            recipients,
            overrideValues
        );
        _assertRoyalties(1, recipients, overrideValues);
        _assertRoyalties(2, recipients, values);

        // Set extension overrides for a specific token
        overrideValues[0] = 3000;

        vm.prank(creator);
        royaltiesExtension.setRoyaltyOverrides(1, recipients, overrideValues);
        _assertRoyalties(1, recipients, overrideValues);
        _assertRoyalties(2, recipients, values);

        // Set creator contract overrides for a specific token
        overrideValues[0] = 4000;

        vm.prank(creator);
        creatorContract.setRoyalties(1, recipients, overrideValues);
        _assertRoyalties(1, recipients, overrideValues);
        _assertRoyalties(2, recipients, values);
    }

    function _assertRoyalties(
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

    function testBurnableExtension() public withBurnableExtension {
        burnableExtension.mint(alice);

        // onBurn can't be called directly by a user
        vm.expectRevert("Can only be called by token creator");
        burnableExtension.onBurn(alice, 1);

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

    /**
     * @dev Fuzz Tests
     */

    function testFuzzTokenURIExtension(
        string memory tokenURI
    ) public withTokenURIExtension {
        // Set token URI
        vm.prank(creator);
        tokenURIExtension.setTokenURI(tokenURI);

        // Returns correct token URI
        tokenURIExtension.mint(alice);
        assertEq(creatorContract.tokenURI(1), tokenURI);
    }

    function testFuzzInvalidExtensionOverride(address extension) public {
        // Ignore Cheat Codes address which will be a false positive
        if (extension == 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D) {
            return;
        }

        // Extension is not a valid contract
        vm.prank(creator);
        vm.expectRevert("Invalid");
        creatorContract.registerExtension(extension, "");
    }
}
