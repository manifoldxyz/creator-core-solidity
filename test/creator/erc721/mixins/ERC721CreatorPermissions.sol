// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {BaseERC721CreatorTest} from "../BaseERC721CreatorTest.sol";
import {ERC721MintPermissions} from "../extensions/ERC721MintPermissions.sol";
import {ERC721Extension} from "../extensions/ERC721Extension.sol";

contract ERC721CreatorPermissionsTest is BaseERC721CreatorTest {
    function testMintPermissions() public {
        // Register the first ERC721Extension
        address extension1 = address(new ERC721Extension(creatorContractAddress));
        vm.prank(creator);
        creatorContract().registerExtension(extension1, extensionTokenURI);

        // Register the second ERC721Extension
        address extension2 = address(new ERC721Extension(creatorContractAddress));
        vm.prank(creator);
        creatorContract().registerExtension(extension2, extensionTokenURI);

        // Deploy mint permissions
        ERC721MintPermissions mintPermissions = new ERC721MintPermissions(
            creatorContractAddress
        );

        // Mint permissions must be a valid contract
        vm.prank(creator);
        vm.expectRevert("Invalid address");
        creatorContract().setMintPermissions(extension1, alice);

        // Set mint permissions
        vm.prank(creator);
        creatorContract().setMintPermissions(extension1, address(mintPermissions));

        // Mint tokens while permissions are enabled
        mintWithExtension(extension1, alice);
        mintWithExtension(extension2, alice);

        // Disable mint permissions
        vm.prank(creator);
        mintPermissions.setApproveEnabled(false);

        // Minting is disabled on the first ERC721Extension, but not second ERC721Extension
        vm.expectRevert("MintPermissions: Disabled");
        mintWithExtension(extension1, alice);
        mintWithExtension(extension2, alice);

        // Mint permissions can be removed
        vm.prank(creator);
        creatorContract().setMintPermissions(extension1, address(0));
        mintWithExtension(extension1, alice);
        mintWithExtension(extension2, alice);
    }

    function testAdminPermissions() public {
        // Set up utilities
        bytes memory revertMessage = "AdminControl: Must be owner or admin";

        address payable[] memory addresses = new address payable[](1);
        addresses[0] = payable(alice);

        string[] memory strings = new string[](1);
        strings[0] = "test";

        uint256[] memory uints = new uint256[](1);
        uints[0] = 1;

        // Alice should not be allowed to do any of the following operations
        vm.startPrank(alice);

        vm.expectRevert(revertMessage);
        creatorContract().registerExtension(alice, extensionTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().registerExtension(alice, extensionTokenURI, true);

        vm.expectRevert(revertMessage);
        creatorContract().unregisterExtension(alice);

        vm.expectRevert(revertMessage);
        creatorContract().blacklistExtension(alice);

        vm.expectRevert(revertMessage);
        creatorContract().setBaseTokenURI(baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().setTokenURIPrefix(baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().setTokenURI(1, baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().setTokenURI(uints, strings);

        vm.expectRevert(revertMessage);
        creatorContract().setMintPermissions(alice, alice);

        vm.expectRevert(revertMessage);
        creatorContract().mintBase(alice);

        vm.expectRevert(revertMessage);
        creatorContract().mintBase(alice, baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().mintBaseBatch(alice, 1);

        vm.expectRevert(revertMessage);
        creatorContract().mintBaseBatch(alice, strings);

        vm.expectRevert(revertMessage);
        creatorContract().setRoyalties(addresses, uints);

        vm.expectRevert(revertMessage);
        creatorContract().setRoyalties(1, addresses, uints);

        vm.expectRevert(revertMessage);
        creatorContract().setRoyaltiesExtension(alice, addresses, uints);

        vm.stopPrank();
    }

    function textExtensionPermissions() private {
        // Set up utilities
        bytes memory revertMessage = "Must be registered ERC721Extension";

        string[] memory strings = new string[](1);
        strings[0] = "test";

        uint256[] memory uints = new uint256[](1);
        uints[0] = 1;

        vm.startPrank(alice);

        vm.expectRevert(revertMessage);
        creatorContract().setBaseTokenURIExtension(baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().setBaseTokenURIExtension(baseTokenURI, true);

        vm.expectRevert(revertMessage);
        creatorContract().setTokenURIPrefixExtension(baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().setTokenURIExtension(1, baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().setTokenURIExtension(uints, strings);

        vm.expectRevert(revertMessage);
        creatorContract().mintExtension(alice);

        vm.expectRevert(revertMessage);
        creatorContract().mintExtension(alice, baseTokenURI);

        vm.expectRevert(revertMessage);
        creatorContract().mintExtensionBatch(alice, 1);

        vm.expectRevert(revertMessage);
        creatorContract().mintExtensionBatch(alice, strings);

        vm.expectRevert(revertMessage);
        creatorContract().setApproveTransferExtension(true);

        vm.stopPrank();
    }
}
