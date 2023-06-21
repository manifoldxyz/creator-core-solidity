// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC721Creator} from "creator-core/ERC721Creator.sol";
import {ICreatorExtensionTokenURI} from "creator-core/extensions/ICreatorExtensionTokenURI.sol";
import {TransferApprovalExtension} from "./extensions/TransferApprovalExtension.sol";
import {TokenURIExtension} from "./extensions/TokenURIExtension.sol";
import {RoyaltiesExtension} from "./extensions/RoyaltiesExtension.sol";
import {BurnableExtension} from "./extensions/BurnableExtension.sol";
import {MintableExtension, IMintableExtension} from "./extensions/MintableExtension.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC165Checker} from "openzeppelin/utils/introspection/ERC165Checker.sol";

contract ERC721CreatorTest is Test {
    ERC721Creator creatorContract;
    TransferApprovalExtension transferApprovalExtension;
    TokenURIExtension tokenURIExtension;
    RoyaltiesExtension royaltiesExtension;
    BurnableExtension burnableExtension;
    MintableExtension mintableExtension;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address creator = address(0xC12EA7012);

    string baseTokenURI = "ipfs://";
    string extensionTokenURI = "ar://";

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
     * @dev Extension helpers
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
        _registerExtension(address(transferApprovalExtension));
        _;
    }

    modifier withTokenURIExtension() {
        vm.prank(creator);
        tokenURIExtension = new TokenURIExtension(address(creatorContract));
        _registerExtension(address(tokenURIExtension));
        _;
    }

    modifier withRoyaltiesExtension() {
        vm.prank(creator);
        royaltiesExtension = new RoyaltiesExtension(address(creatorContract));
        _registerExtension(address(royaltiesExtension));
        _;
    }

    modifier withBurnableExtension() {
        vm.prank(creator);
        burnableExtension = new BurnableExtension(address(creatorContract));
        _registerExtension(address(burnableExtension));
        _;
    }

    modifier withMintableExtension() {
        vm.prank(creator);
        mintableExtension = new MintableExtension(address(creatorContract));
        _registerExtension(address(mintableExtension));
        _;
    }

    function _registerExtension(address extension) private {
        vm.prank(creator);
        creatorContract.registerExtension(extension, extensionTokenURI);
    }

    /**
     * @dev Mint helpers
     */

    function mintWithCreator(address to) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = creatorContract.mintBase(to);

        // Assert mint was successful
        assertMintWithCreator(tokenId, to, _tokenURI(baseTokenURI, tokenId));

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

    function mintWithExtension(
        address extension,
        address to
    ) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = IMintableExtension(extension).mint(to);

        // Assert mint was successful
        assertMintWithExtension(
            extension,
            tokenId,
            to,
            _tokenURI(extensionTokenURI, tokenId)
        );

        return tokenId;
    }

    function mintWithExtension(
        address extension,
        address to,
        string memory uri
    ) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = IMintableExtension(extension).mint(to, uri);

        // Assert mint was successful
        assertMintWithExtension(extension, tokenId, to, uri);

        return tokenId;
    }

    function assertMintWithCreator(
        uint256 tokenId,
        address to,
        string memory uri
    ) internal {
        assertMintWithExtension(address(0), tokenId, to, uri);
    }

    function assertMintWithExtension(
        address extension,
        uint256 tokenId,
        address to,
        string memory uri
    ) internal {
        // Check balance change
        assertEq(creatorContract.ownerOf(tokenId), to);

        // Check token URI
        if (
            ERC165Checker.supportsInterface(
                extension,
                type(ICreatorExtensionTokenURI).interfaceId
            )
        ) {
            // If extension overrides token URI, set that as expected
            uri = ICreatorExtensionTokenURI(extension).tokenURI(
                address(creatorContract),
                tokenId
            );
        }
        assertEq(creatorContract.tokenURI(tokenId), uri);

        // Check extension registration
        if (extension == address(0)) {
            // If mint via creator, validate no extension was registered
            vm.expectRevert();
            creatorContract.tokenExtension(tokenId);
        } else {
            // Otherwise, validate extension was registered during mint
            assertEq(creatorContract.tokenExtension(tokenId), extension);
        }
    }

    function _tokenURI(
        string memory uri,
        uint256 tokenId
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(uri, Strings.toString(tokenId)));
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
