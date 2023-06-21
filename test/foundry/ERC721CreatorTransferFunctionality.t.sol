// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721CreatorTest} from "./helpers/ERC721CreatorTest.sol";
import {TransferApprovalExtension} from "./helpers/extensions/TransferApprovalExtension.sol";

contract ERC721CreatorTransferFunctionalityTest is ERC721CreatorTest {
    TransferApprovalExtension transferApprovalExtension;

    function setUp() public override {
        super.setUp();
        vm.prank(creator);
        transferApprovalExtension = new TransferApprovalExtension(
            address(creatorContract)
        );
        // Supports legacy interfaces
        assertTrue(
            transferApprovalExtension.supportsInterface(bytes4(0x7005caad))
        );
        assertTrue(
            transferApprovalExtension.supportsInterface(bytes4(0x45ffcdad))
        );
        _registerExtension(address(transferApprovalExtension));
    }

    function testTransferApprovalExtension() public {
        // Mints bypass approvals
        mintWithExtension(address(transferApprovalExtension), alice);

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
}
