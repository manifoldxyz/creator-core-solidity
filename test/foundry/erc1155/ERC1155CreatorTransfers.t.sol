// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC1155CreatorTest } from "./helpers/ERC1155CreatorTest.sol";
import {
    ERC1155TransferApprovalExtension
} from "./helpers/extensions/ERC1155TransferApprovalExtension.sol";

contract ERC1155CreatorTransfersTest is ERC1155CreatorTest {
    ERC1155TransferApprovalExtension transferApprovalExtension;

    function setUp() public override {
        super.setUp();
        vm.prank(creator);
        transferApprovalExtension = new ERC1155TransferApprovalExtension(
            address(creatorContract)
        );
        _registerExtension(address(transferApprovalExtension));
    }

    function testTransferApprovalBase() public {
        // Deploy new extension for the base transfer approval
        ERC1155TransferApprovalExtension baseExtension = new ERC1155TransferApprovalExtension(
                address(creatorContract)
            );

        // Enable the extension
        vm.prank(creator);
        baseExtension.setApproveEnabled(true);

        // Only creator can set the base transfer approval extension
        vm.prank(alice);
        vm.expectRevert("AdminControl: Must be owner or admin");
        creatorContract.setApproveTransfer(address(baseExtension));

        // Set the base transfer approval extension
        vm.prank(creator);
        creatorContract.setApproveTransfer(address(baseExtension));

        // Validate the base transfer approval extension
        assertEq(address(baseExtension), creatorContract.getApproveTransfer());

        // Mint tokens
        uint256[] memory tokenIds = mintBatchWithCreator(alice, 3);

        // Transfer tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(alice);
            creatorContract.safeTransferFrom(alice, bob, tokenIds[i], 1, "");
        }

        // Disable the base transfer approval extension
        vm.prank(creator);
        baseExtension.setApproveEnabled(false);

        // Validate tokens can't be transferred
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(bob);
            vm.expectRevert("Extension approval failure");
            creatorContract.safeTransferFrom(bob, alice, tokenIds[i], 1, "");
        }

        // Disable the base transfer approval extension
        vm.prank(creator);
        creatorContract.setApproveTransfer(address(0));

        // Validate the base transfer approval extension
        assertEq(address(0), creatorContract.getApproveTransfer());

        // Validate tokens can be transferred
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(bob);
            creatorContract.safeTransferFrom(bob, alice, tokenIds[i], 1, "");
        }
    }

    function testTransferApprovalExtension() public {
        // Enable the extension
        vm.prank(creator);
        transferApprovalExtension.setApproveEnabled(true);

        // Mint tokens
        uint256[] memory tokenIds = mintBatchWithExtension(
            address(transferApprovalExtension),
            alice,
            3
        );

        // Transfer tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(alice);
            creatorContract.safeTransferFrom(alice, bob, tokenIds[i], 1, "");
        }

        // Disable the base transfer approval extension
        vm.prank(creator);
        transferApprovalExtension.setApproveEnabled(false);

        // Validate tokens can't be transferred
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(bob);
            vm.expectRevert("Extension approval failure");
            creatorContract.safeTransferFrom(bob, alice, tokenIds[i], 1, "");
        }

        // Unregister the extension
        vm.prank(creator);
        creatorContract.unregisterExtension(address(transferApprovalExtension));

        // Validate tokens can't be transferred without extension
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(bob);
            vm.expectRevert("Extension approval failure");
            creatorContract.safeTransferFrom(bob, alice, tokenIds[i], 1, "");
        }
    }
}
