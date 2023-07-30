// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseCreatorTest } from "./BaseCreatorTest.sol";
import { ERC1155Creator } from "creator-core/ERC1155Creator.sol";
import {
    ICreatorExtensionTokenURI
} from "creator-core/extensions/ICreatorExtensionTokenURI.sol";
import { IERC1155Extension } from "./erc1155/helpers/ERC1155Extension.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import {
    ERC165Checker
} from "openzeppelin/utils/introspection/ERC165Checker.sol";

contract ERC1155CreatorTest is BaseCreatorTest {
    ERC1155Creator creatorContract;

    function setUp() public virtual override {
        super.setUp();

        // Deploy creator contract
        vm.prank(creator);
        creatorContract = new ERC1155Creator("Test", "TEST");

        // Set base token URI
        vm.prank(creator);
        creatorContract.setBaseTokenURI(baseTokenURI);
    }

    /**
     * @dev Mint helpers
     */

    function mintWithCreator(
        address[] memory tos,
        uint256[] memory amounts,
        string[] memory uris
    ) internal returns (uint256[] memory) {
        vm.prank(creator);
        uint256[] memory tokenIds = creatorContract.mintBaseNew(
            tos,
            amounts,
            uris
        );

        if (tokenIds.length > 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                string memory uri = _uri(baseTokenURI, tokenIds[i]);
                if (uris.length == 1 && bytes(uris[0]).length > 0) {
                    uri = uris[0];
                } else if (uris.length > 1 && bytes(uris[i]).length > 0) {
                    uri = uris[i];
                }
                assertMintWithCreator(
                    tokenIds[i],
                    tos.length == 1 ? tos[0] : tos[i],
                    amounts[i],
                    uri
                );
            }
            return tokenIds;
        }

        // reverted, seed 0 to prevent index out of bounds
        tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        return tokenIds;
    }

    function mintWithCreator(
        address[] memory tos,
        uint256[] memory amounts,
        string memory uri
    ) internal returns (uint256) {
        string[] memory uris = new string[](1);
        uris[0] = uri;
        uint256[] memory tokenIds = mintWithCreator(tos, amounts, uris);
        return tokenIds[0];
    }

    function mintWithCreator(
        address[] memory tos,
        uint256 amount,
        string memory uri
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        return mintWithCreator(tos, amounts, uri);
    }

    function mintWithCreator(
        address to,
        uint256 amount,
        string memory uri
    ) internal returns (uint256) {
        address[] memory tos = new address[](1);
        tos[0] = to;
        return mintWithCreator(tos, amount, uri);
    }

    function mintWithCreator(
        address[] memory tos,
        uint256[] memory amounts
    ) internal returns (uint256) {
        string[] memory uris = new string[](0);
        uint256[] memory tokenIds = mintWithCreator(tos, amounts, uris);
        return tokenIds[0];
    }

    function mintWithCreator(
        address[] memory tos,
        uint256 amount
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        return mintWithCreator(tos, amounts);
    }

    function mintWithCreator(
        address to,
        uint256 amount
    ) internal returns (uint256) {
        address[] memory tos = new address[](1);
        tos[0] = to;
        return mintWithCreator(tos, amount);
    }

    function mintWithCreator(
        address[] memory tos,
        string memory uri
    ) internal returns (uint256) {
        return mintWithCreator(tos, 1, uri);
    }

    function mintWithCreator(
        address to,
        string memory uri
    ) internal returns (uint256) {
        address[] memory tos = new address[](1);
        tos[0] = to;
        return mintWithCreator(tos, 1, uri);
    }

    function mintWithCreator(address[] memory tos) internal returns (uint256) {
        return mintWithCreator(tos, 1);
    }

    function mintWithCreator(address to) internal returns (uint256) {
        address[] memory tos = new address[](1);
        tos[0] = to;
        return mintWithCreator(tos);
    }

    function mintBatchWithCreator(
        address to,
        uint256 amount
    ) internal returns (uint256[] memory) {
        address[] memory tos = new address[](1);
        tos[0] = to;

        uint256[] memory amounts = new uint256[](amount);
        string[] memory uris = new string[](amount);

        for (uint256 i = 0; i < amount; i++) {
            amounts[i] = 1;
            uris[i] = "";
        }

        return mintWithCreator(tos, amounts, uris);
    }

    function mintBatchWithCreator(
        address to,
        string[] memory uris
    ) internal returns (uint256[] memory) {
        address[] memory tos = new address[](1);
        tos[0] = to;

        uint256[] memory amounts = new uint256[](uris.length);
        for (uint256 i = 0; i < uris.length; i++) {
            amounts[i] = 1;
        }

        return mintWithCreator(tos, amounts, uris);
    }

    function mintWithExtension(
        address extension,
        address[] memory tos,
        uint256[] memory amounts,
        string[] memory uris
    ) internal returns (uint256[] memory) {
        vm.prank(creator);
        uint256[] memory tokenIds = IERC1155Extension(extension).mint(
            tos,
            amounts,
            uris
        );

        if (tokenIds.length > 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                string memory uri = _uri(extensionTokenURI, tokenIds[i]);
                if (uris.length == 1 && bytes(uris[0]).length > 0) {
                    uri = uris[0];
                } else if (uris.length > 1 && bytes(uris[i]).length > 0) {
                    uri = uris[i];
                }
                assertMintWithExtension(
                    extension,
                    tokenIds[i],
                    tos.length == 1 ? tos[0] : tos[i],
                    amounts[i],
                    uri
                );
            }
            return tokenIds;
        }

        // reverted, seed 0 to prevent index out of bounds
        tokenIds = new uint256[](1);
        tokenIds[0] = 0;
        return tokenIds;
    }

    function mintWithExtension(
        address extension,
        address[] memory tos,
        uint256[] memory amounts,
        string memory uri
    ) internal returns (uint256) {
        string[] memory uris = new string[](1);
        uris[0] = uri;
        uint256[] memory tokenIds = mintWithExtension(
            extension,
            tos,
            amounts,
            uris
        );
        return tokenIds[0];
    }

    function mintWithExtension(
        address extension,
        address[] memory tos,
        uint256 amount,
        string memory uri
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        return mintWithExtension(extension, tos, amounts, uri);
    }

    function mintWithExtension(
        address extension,
        address to,
        uint256 amount,
        string memory uri
    ) internal returns (uint256) {
        address[] memory tos = new address[](1);
        tos[0] = to;
        return mintWithExtension(extension, tos, amount, uri);
    }

    function mintWithExtension(
        address extension,
        address[] memory tos,
        uint256[] memory amounts
    ) internal returns (uint256) {
        string[] memory uris = new string[](0);
        uint256[] memory tokenIds = mintWithExtension(
            extension,
            tos,
            amounts,
            uris
        );
        return tokenIds[0];
    }

    function mintWithExtension(
        address extension,
        address[] memory tos,
        uint256 amount
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        return mintWithExtension(extension, tos, amounts);
    }

    function mintWithExtension(
        address extension,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        address[] memory tos = new address[](1);
        tos[0] = to;
        return mintWithExtension(extension, tos, amount);
    }

    function mintWithExtension(
        address extension,
        address[] memory tos,
        string memory uri
    ) internal returns (uint256) {
        return mintWithExtension(extension, tos, 1, uri);
    }

    function mintWithExtension(
        address extension,
        address to,
        string memory uri
    ) internal returns (uint256) {
        address[] memory tos = new address[](1);
        tos[0] = to;
        return mintWithExtension(extension, tos, 1, uri);
    }

    function mintWithExtension(
        address extension,
        address[] memory tos
    ) internal returns (uint256) {
        return mintWithExtension(extension, tos, 1);
    }

    function mintWithExtension(
        address extension,
        address to
    ) internal returns (uint256) {
        address[] memory tos = new address[](1);
        tos[0] = to;
        return mintWithExtension(extension, tos);
    }

    function mintBatchWithExtension(
        address extension,
        address to,
        uint256 amount
    ) internal returns (uint256[] memory) {
        address[] memory tos = new address[](1);
        tos[0] = to;

        uint256[] memory amounts = new uint256[](amount);
        string[] memory uris = new string[](amount);

        for (uint256 i = 0; i < amount; i++) {
            amounts[i] = 1;
            uris[i] = "";
        }

        return mintWithExtension(extension, tos, amounts, uris);
    }

    function mintBatchWithExtension(
        address extension,
        address to,
        string[] memory uris
    ) internal returns (uint256[] memory) {
        address[] memory tos = new address[](1);
        tos[0] = to;

        uint256[] memory amounts = new uint256[](uris.length);
        for (uint256 i = 0; i < uris.length; i++) {
            amounts[i] = 1;
        }

        return mintWithExtension(extension, tos, amounts, uris);
    }

    function assertMintWithCreator(
        uint256 tokenId,
        address to,
        uint256 amount,
        string memory uri
    ) internal {
        // Validate mint was successful
        assertMint(tokenId, to, amount, uri);

        // If mint via creator, validate no extension was registered
        vm.expectRevert();
        creatorContract.tokenExtension(tokenId);
    }

    function assertMintWithExtension(
        address extension,
        uint256 tokenId,
        address to,
        uint256 amount,
        string memory uri
    ) internal {
        // Update token  URI if needed
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

        // Validate mint was successful
        assertMint(tokenId, to, amount, uri);

        // Validate extension was registered during mint
        assertEq(creatorContract.tokenExtension(tokenId), extension);
    }

    function assertMint(
        uint256 tokenId,
        address to,
        uint256 amount,
        string memory uri
    ) internal {
        // Check balance change
        assertEq(creatorContract.balanceOf(to, tokenId), amount);

        // Check token URI
        assertEq(creatorContract.uri(tokenId), uri);
    }
}
