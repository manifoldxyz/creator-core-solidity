// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {BaseERC721CreatorTest} from "../BaseERC721CreatorTest.sol";
import {ERC721TransferApprovalExtension} from "../extensions/ERC721TransferApprovalExtension.sol";

contract ERC721CreatorTransfersTest is BaseERC721CreatorTest {
    ERC721TransferApprovalExtension public transferApprovalExtension;

    modifier withTransferApprovalExtension() {
        vm.prank(creator);
        transferApprovalExtension = new ERC721TransferApprovalExtension(
            creatorContractAddress
        );
        // Supports legacy interfaces
        assertTrue(transferApprovalExtension.supportsInterface(bytes4(0x7005caad)));
        assertTrue(transferApprovalExtension.supportsInterface(bytes4(0x45ffcdad)));
        vm.prank(creator);
        creatorContract().registerExtension(address(transferApprovalExtension), extensionTokenURI);
        _;
    }

    function testTransferApprovalBase() public withTransferApprovalExtension {
        // Deploy new extension for the base transfer approval
        ERC721TransferApprovalExtension baseExtension = new ERC721TransferApprovalExtension(
                creatorContractAddress
            );

        // Enable the extension
        vm.prank(creator);
        baseExtension.setApproveEnabled(true);

        // Only creator can set the base transfer approval extension
        vm.prank(alice);
        vm.expectRevert("AdminControl: Must be owner or admin");
        creatorContract().setApproveTransfer(address(baseExtension));

        // Set the base transfer approval extension
        vm.prank(creator);
        creatorContract().setApproveTransfer(address(baseExtension));

        // Validate the base transfer approval extension
        assertEq(address(baseExtension), creatorContract().getApproveTransfer());

        // Mint tokens
        uint256[] memory tokenIds = mintBatchWithCreator(alice, 3);

        // Transfer tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(alice);
            creatorContract().safeTransferFrom(alice, bob, tokenIds[i]);
        }

        // Disable the base transfer approval extension
        vm.prank(creator);
        baseExtension.setApproveEnabled(false);

        // Validate tokens can't be transferred
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(bob);
            vm.expectRevert("Extension approval failure");
            creatorContract().safeTransferFrom(bob, alice, tokenIds[i]);
        }

        // Disable the base transfer approval extension
        vm.prank(creator);
        creatorContract().setApproveTransfer(address(0));

        // Validate the base transfer approval extension
        assertEq(address(0), creatorContract().getApproveTransfer());

        // Validate tokens can be transferred
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(bob);
            creatorContract().safeTransferFrom(bob, alice, tokenIds[i]);
        }
    }

    function testTransferApprovalExtension() public withTransferApprovalExtension {
        // Enable the extension
        vm.prank(creator);
        transferApprovalExtension.setApproveEnabled(true);

        // Mint tokens
        uint256[] memory tokenIds = mintBatchWithExtension(address(transferApprovalExtension), alice, 3);

        // Transfer tokens
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(alice);
            creatorContract().safeTransferFrom(alice, bob, tokenIds[i]);
        }

        // Disable the base transfer approval extension
        vm.prank(creator);
        transferApprovalExtension.setApproveEnabled(false);

        // Validate tokens can't be transferred
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(bob);
            vm.expectRevert("Extension approval failure");
            creatorContract().safeTransferFrom(bob, alice, tokenIds[i]);
        }

        // Unregister the extension
        vm.prank(creator);
        creatorContract().unregisterExtension(address(transferApprovalExtension));

        // Validate tokens can't be transferred without extension
        for (uint256 i = 0; i < tokenIds.length; i++) {
            vm.prank(bob);
            vm.expectRevert("Extension approval failure");
            creatorContract().safeTransferFrom(bob, alice, tokenIds[i]);
        }
    }
}
