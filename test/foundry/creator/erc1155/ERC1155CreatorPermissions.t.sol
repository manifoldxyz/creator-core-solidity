// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC1155CreatorTest } from "../ERC1155CreatorTest.sol";
import {
    ERC1155MintPermissions
} from "./helpers/ERC1155MintPermissions.sol";
import { ERC1155Extension } from "./helpers/ERC1155Extension.sol";

contract ERC1155CreatorPermissionsTest is ERC1155CreatorTest {
    function testMintPermissions() public {
        // Register the first ERC1155Extension
        address extension1 = address(
            new ERC1155Extension(address(creatorContract))
        );
        vm.prank(creator);
        creatorContract.registerExtension(extension1, extensionTokenURI);

        // Register the second ERC1155Extension
        address extension2 = address(
            new ERC1155Extension(address(creatorContract))
        );
        vm.prank(creator);
        creatorContract.registerExtension(extension2, extensionTokenURI);

        // Deploy mint permissions
        ERC1155MintPermissions mintPermissions = new ERC1155MintPermissions(
            address(creatorContract)
        );

        // Mint permissions must be a valid contract
        vm.prank(creator);
        vm.expectRevert("Invalid address");
        creatorContract.setMintPermissions(extension1, alice);

        // Set mint permissions
        vm.prank(creator);
        creatorContract.setMintPermissions(
            extension1,
            address(mintPermissions)
        );

        // Mint tokens while permissions are enabled
        mintWithExtension(extension1, alice);
        mintWithExtension(extension2, alice);

        // Disable mint permissions
        vm.prank(creator);
        mintPermissions.setApproveEnabled(false);

        // Minting is disabled on the first ERC1155Extension, but not second ERC1155Extension
        vm.expectRevert("MintPermissions: Disabled");
        mintWithExtension(extension1, alice);
        mintWithExtension(extension2, alice);

        // Mint permissions can be removed
        vm.prank(creator);
        creatorContract.setMintPermissions(extension1, address(0));
        mintWithExtension(extension1, alice);
        mintWithExtension(extension2, alice);
    }

    function testAdminPermissions() public {
        // Set up utilities
        bytes memory revertMessage = "AdminControl: Must be owner or admin";

        address[] memory addresses = new address[](1);
        addresses[0] = alice;

        address payable[] memory payableAddresses = new address payable[](1);
        addresses[0] = payable(alice);

        string[] memory strings = new string[](1);
        strings[0] = "test";

        uint256[] memory uints = new uint256[](1);
        uints[0] = 1;

        // Alice should not be allowed to do any of the following operations
        vm.startPrank(alice);

        vm.expectRevert(revertMessage);
        creatorContract.registerExtension(alice, extensionTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract.registerExtension(alice, extensionTokenURI, true);

        vm.expectRevert(revertMessage);
        creatorContract.unregisterExtension(alice);

        vm.expectRevert(revertMessage);
        creatorContract.blacklistExtension(alice);

        vm.expectRevert(revertMessage);
        creatorContract.setBaseTokenURI(baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract.setTokenURIPrefix(baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract.setTokenURI(1, baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract.setTokenURI(uints, strings);

        vm.expectRevert(revertMessage);
        creatorContract.setMintPermissions(alice, alice);

        vm.expectRevert(revertMessage);
        creatorContract.mintBaseNew(addresses, uints, strings);

        vm.expectRevert(revertMessage);
        creatorContract.mintBaseExisting(addresses, uints, uints);

        vm.expectRevert(revertMessage);
        creatorContract.setRoyalties(payableAddresses, uints);

        vm.expectRevert(revertMessage);
        creatorContract.setRoyalties(1, payableAddresses, uints);

        vm.expectRevert(revertMessage);
        creatorContract.setRoyaltiesExtension(alice, payableAddresses, uints);

        vm.stopPrank();
    }

    function textExtensionPermissions() private {
        // Set up utilities
        bytes memory revertMessage = "Must be registered ERC1155Extension";

        address[] memory addresses = new address[](1);
        addresses[0] = alice;

        string[] memory strings = new string[](1);
        strings[0] = "test";

        uint256[] memory uints = new uint256[](1);
        uints[0] = 1;

        vm.startPrank(alice);

        vm.expectRevert(revertMessage);
        creatorContract.setBaseTokenURIExtension(baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract.setBaseTokenURIExtension(baseTokenURI, true);

        vm.expectRevert(revertMessage);
        creatorContract.setTokenURIPrefixExtension(baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract.setTokenURIExtension(1, baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract.setTokenURIExtension(uints, strings);

        vm.expectRevert(revertMessage);
        creatorContract.mintExtensionNew(addresses, uints, strings);

        vm.expectRevert(revertMessage);
        creatorContract.mintExtensionExisting(addresses, uints, uints);

        vm.expectRevert(revertMessage);
        creatorContract.setApproveTransferExtension(true);

        vm.stopPrank();
    }
}
