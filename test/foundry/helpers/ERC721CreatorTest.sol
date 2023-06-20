// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC721Creator} from "creator-core/ERC721Creator.sol";
import {TransferApprovalExtension} from "./extensions/TransferApprovalExtension.sol";
import {TokenURIExtension} from "./extensions/TokenURIExtension.sol";
import {RoyaltiesExtension} from "./extensions/RoyaltiesExtension.sol";
import {BurnableExtension} from "./extensions/BurnableExtension.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

contract ERC721CreatorTest is Test {
    ERC721Creator creatorContract;
    TransferApprovalExtension transferApprovalExtension;
    TokenURIExtension tokenURIExtension;
    RoyaltiesExtension royaltiesExtension;
    BurnableExtension burnableExtension;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address creator = address(0xC12EA7012);

    string baseTokenURI = "ipfs://";

    function setUp() public {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(creator, "creator");
        _setUpCreatorContract();
    }

    function _setUpCreatorContract() private {
        // Deploy creator contract
        vm.prank(creator);
        creatorContract = new ERC721Creator("Test", "TEST");

        // Set base token URI
        vm.prank(creator);
        creatorContract.setBaseTokenURI(baseTokenURI);
    }

    /**
     * @dev Extension support helpers
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

    /**
     * @dev Mint helpers
     */

    function mintWithCreator(address to) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = creatorContract.mintBase(to);

        // Assert mint was successful
        assertMintWithCreator(
            tokenId,
            to,
            string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)))
        );

        return tokenId;
    }

    function mintWithCreator(
        address to,
        string memory uri
    ) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = creatorContract.mintBase(to, uri);

        // Assert mint was successful
        assertMintWithCreator(tokenId, to, uri);

        return tokenId;
    }

    function assertMintWithCreator(
        uint256 tokenId,
        address to,
        string memory uri
    ) internal {
        // Check balances and tokenURI
        assertEq(creatorContract.ownerOf(tokenId), to);
        assertEq(creatorContract.tokenURI(tokenId), uri);

        // Validate no extension was registered
        vm.expectRevert();
        creatorContract.tokenExtension(tokenId);
    }

    /**
     * @dev Royalty helpers
     */

    function assertRoyalties(
        uint256 tokenId,
        address payable[] memory expectedRecipients,
        uint256[] memory expectedValues
    ) internal {
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
