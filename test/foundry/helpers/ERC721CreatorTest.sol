// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC721Creator} from "creator-core/ERC721Creator.sol";
import {TransferApprovalExtension} from "./extensions/TransferApprovalExtension.sol";
import {TokenURIExtension} from "./extensions/TokenURIExtension.sol";
import {RoyaltiesExtension} from "./extensions/RoyaltiesExtension.sol";
import {BurnableExtension} from "./extensions/BurnableExtension.sol";

contract ERC721CreatorTest is Test {
    ERC721Creator creatorContract;
    TransferApprovalExtension transferApprovalExtension;
    TokenURIExtension tokenURIExtension;
    RoyaltiesExtension royaltiesExtension;
    BurnableExtension burnableExtension;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address creator = address(0xC12EA7012);

    function setUp() public {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(creator, "creator");
        _setUpCreatorContract();
    }

    /**
     * @dev Test helpers
     */

    modifier withTransferApprovalExtension() {
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

        vm.prank(creator);
        creatorContract.registerExtension(
            address(transferApprovalExtension),
            ""
        );

        _;
    }

    modifier withTokenURIExtension() {
        vm.prank(creator);
        tokenURIExtension = new TokenURIExtension(address(creatorContract));

        vm.prank(creator);
        creatorContract.registerExtension(address(tokenURIExtension), "");

        _;
    }

    modifier withRoyaltiesExtension() {
        vm.prank(creator);
        royaltiesExtension = new RoyaltiesExtension(address(creatorContract));

        vm.prank(creator);
        creatorContract.registerExtension(address(royaltiesExtension), "");

        _;
    }

    modifier withBurnableExtension() {
        vm.prank(creator);
        burnableExtension = new BurnableExtension(address(creatorContract));

        vm.prank(creator);
        creatorContract.registerExtension(address(burnableExtension), "");

        _;
    }

    function _setUpCreatorContract() private {
        vm.prank(creator);
        creatorContract = new ERC721Creator("Test", "TEST");
    }
}
