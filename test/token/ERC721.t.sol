// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

// @dev The majority of this test file was taken from Solmate with some modifications
// https://github.com/transmissions11/solmate/blob/main/src/test/ERC721.t.sol

import {Test} from "forge-std/Test.sol";
import {MockERC721} from "./helpers/ERC721.sol";

abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract ERC721Recipient is ERC721TokenReceiver {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
    }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient {}

contract ERC721Test is Test, ERC721Recipient {
    address public token;

    function setUp() public virtual {
        token = address(new MockERC721("Token", "TKN"));
    }

    function _token() internal view returns (MockERC721) {
        return MockERC721(token);
    }

    function invariantMetadata() public {
        assertEq(_token().name(), "Token");
        assertEq(_token().symbol(), "TKN");
    }

    function testSupportsInterface() public {
        assertTrue(_token().supportsInterface(0x80ac58cd)); // ERC-721
        assertTrue(_token().supportsInterface(0x5b5e139f)); // ERC-721 Metadata
    }

    function testMint() public {
        _token().mint(address(0xBEEF), 1337);

        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().ownerOf(1337), address(0xBEEF));
    }

    function testBurn() public {
        _token().mint(address(0xBEEF), 1337);
        _token().burn(1337);

        assertEq(_token().balanceOf(address(0xBEEF)), 0);

        vm.expectRevert();
        _token().ownerOf(1337);
    }

    function testApprove() public {
        _token().mint(address(this), 1337);

        _token().approve(address(0xBEEF), 1337);

        assertEq(_token().getApproved(1337), address(0xBEEF));
    }

    function testApproveBurn() public {
        _token().mint(address(this), 1337);

        _token().approve(address(0xBEEF), 1337);

        _token().burn(1337);

        assertEq(_token().balanceOf(address(this)), 0);

        vm.expectRevert();
        assertEq(_token().getApproved(1337), address(0));

        vm.expectRevert();
        _token().ownerOf(1337);
    }

    function testApproveAll() public {
        _token().setApprovalForAll(address(0xBEEF), true);

        assertTrue(_token().isApprovedForAll(address(this), address(0xBEEF)));
    }

    function testTransferFrom() public {
        address from = address(0xABCD);

        _token().mint(from, 1337);

        vm.prank(from);
        _token().approve(address(this), 1337);

        _token().transferFrom(from, address(0xBEEF), 1337);

        assertEq(_token().getApproved(1337), address(0));
        assertEq(_token().ownerOf(1337), address(0xBEEF));
        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testTransferFromSelf() public {
        _token().mint(address(this), 1337);

        _token().transferFrom(address(this), address(0xBEEF), 1337);

        assertEq(_token().getApproved(1337), address(0));
        assertEq(_token().ownerOf(1337), address(0xBEEF));
        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll() public {
        address from = address(0xABCD);

        _token().mint(from, 1337);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().transferFrom(from, address(0xBEEF), 1337);

        assertEq(_token().getApproved(1337), address(0));
        assertEq(_token().ownerOf(1337), address(0xBEEF));
        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA() public {
        address from = address(0xABCD);

        _token().mint(from, 1337);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, address(0xBEEF), 1337);

        assertEq(_token().getApproved(1337), address(0));
        assertEq(_token().ownerOf(1337), address(0xBEEF));
        assertEq(_token().balanceOf(address(0xBEEF)), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        _token().mint(from, 1337);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, address(recipient), 1337);

        assertEq(_token().getApproved(1337), address(0));
        assertEq(_token().ownerOf(1337), address(recipient));
        assertEq(_token().balanceOf(address(recipient)), 1);
        assertEq(_token().balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData() public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        _token().mint(from, 1337);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, address(recipient), 1337, "testing 123");

        assertEq(_token().getApproved(1337), address(0));
        assertEq(_token().ownerOf(1337), address(recipient));
        assertEq(_token().balanceOf(address(recipient)), 1);
        assertEq(_token().balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), 1337);
        assertEq(recipient.data(), "testing 123");
    }

    function testSafeMintToEOA() public {
        _token().mint(address(0xBEEF), 1337);

        assertEq(_token().ownerOf(1337), address(address(0xBEEF)));
        assertEq(_token().balanceOf(address(address(0xBEEF))), 1);
    }

    function testSafeMintToERC721Recipient() public {
        ERC721Recipient to = new ERC721Recipient();

        _token().mint(address(to), 1337);

        assertEq(_token().ownerOf(1337), address(to));
        assertEq(_token().balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData() public {
        ERC721Recipient to = new ERC721Recipient();

        _token().mint(address(to), 1337, "testing 123");

        assertEq(_token().ownerOf(1337), address(to));
        assertEq(_token().balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1337);
        assertEq(to.data(), "testing 123");
    }

    function testFailMintToZero() public {
        _token().mint(address(0), 1337);
    }

    function testFailDoubleMint() public {
        _token().mint(address(0xBEEF), 1337);
        _token().mint(address(0xBEEF), 1337);
    }

    function testFailBurnUnMinted() public {
        _token().burn(1337);
    }

    function testFailDoubleBurn() public {
        _token().mint(address(0xBEEF), 1337);

        _token().burn(1337);
        _token().burn(1337);
    }

    function testFailApproveUnMinted() public {
        _token().approve(address(0xBEEF), 1337);
    }

    function testFailApproveUnAuthorized() public {
        _token().mint(address(0xCAFE), 1337);

        _token().approve(address(0xBEEF), 1337);
    }

    function testFailTransferFromUnOwned() public {
        _token().transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailTransferFromWrongFrom() public {
        _token().mint(address(0xCAFE), 1337);

        _token().transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailTransferFromToZero() public {
        _token().mint(address(this), 1337);

        _token().transferFrom(address(this), address(0), 1337);
    }

    function testFailTransferFromNotOwner() public {
        _token().mint(address(0xFEED), 1337);

        _token().transferFrom(address(0xFEED), address(0xBEEF), 1337);
    }

    function testFailSafeTransferFromToNonERC721Recipient() public {
        _token().mint(address(this), 1337);

        _token().safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData() public {
        _token().mint(address(this), 1337);

        _token().safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeTransferFromToRevertingERC721Recipient() public {
        _token().mint(address(this), 1337);

        _token().safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData() public {
        _token().mint(address(this), 1337);

        _token().safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData() public {
        _token().mint(address(this), 1337);

        _token().safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
        _token().mint(address(this), 1337);

        _token().safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeMintToNonERC721Recipient() public {
        _token().mint(address(new NonERC721Recipient()), 1337);
    }

    function testFailSafeMintToNonERC721RecipientWithData() public {
        _token().mint(address(new NonERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeMintToRevertingERC721Recipient() public {
        _token().mint(address(new RevertingERC721Recipient()), 1337);
    }

    function testFailSafeMintToRevertingERC721RecipientWithData() public {
        _token().mint(address(new RevertingERC721Recipient()), 1337, "testing 123");
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnData() public {
        _token().mint(address(new WrongReturnDataERC721Recipient()), 1337);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData() public {
        _token().mint(address(new WrongReturnDataERC721Recipient()), 1337, "testing 123");
    }

    function testFailBalanceOfZeroAddress() public view {
        _token().balanceOf(address(0));
    }

    function testFailOwnerOfUnminted() public view {
        _token().ownerOf(1337);
    }

    function testMetadata(string memory name, string memory symbol) public {
        MockERC721 tkn = new MockERC721(name, symbol);

        assertEq(tkn.name(), name);
        assertEq(tkn.symbol(), symbol);
    }

    function testMint(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);
        
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) to = address(0xBEEF);

        _token().mint(to, id);

        assertEq(_token().balanceOf(to), 1);
        assertEq(_token().ownerOf(id), to);
    }

    function testBurn(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);
        
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) to = address(0xBEEF);

        _token().mint(to, id);
        _token().burn(id);

        assertEq(_token().balanceOf(to), 0);

        vm.expectRevert();
        _token().ownerOf(id);
    }

    function testApprove(address to, uint256 id) public {
        if (to == address(0)) to = address(0xBEEF);
        
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) to = address(0xBEEF);

        _token().mint(address(this), id);

        _token().approve(to, id);

        assertEq(_token().getApproved(id), to);
    }

    function testApproveBurn(address to, uint256 id) public {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) to = address(0xBEEF);

        _token().mint(address(this), id);

        _token().approve(address(to), id);

        _token().burn(id);

        assertEq(_token().balanceOf(address(this)), 0);

        vm.expectRevert();
        assertEq(_token().getApproved(id), address(0));

        vm.expectRevert();
        _token().ownerOf(id);
    }

    function testApproveAll(address to, bool approved) public {
        _token().setApprovalForAll(to, approved);

        assertEq(_token().isApprovedForAll(address(this), to), approved);
    }

    function testTransferFrom(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        _token().mint(from, id);

        vm.prank(from);
        _token().approve(address(this), id);

        _token().transferFrom(from, to, id);

        assertEq(_token().getApproved(id), address(0));
        assertEq(_token().ownerOf(id), to);
        assertEq(_token().balanceOf(to), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testTransferFromSelf(uint256 id, address to) public {
        if (to == address(0) || to == address(this)) to = address(0xBEEF);

        _token().mint(address(this), id);

        _token().transferFrom(address(this), to, id);

        assertEq(_token().getApproved(id), address(0));
        assertEq(_token().ownerOf(id), to);
        assertEq(_token().balanceOf(to), 1);
        assertEq(_token().balanceOf(address(this)), 0);
    }

    function testTransferFromApproveAll(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        _token().mint(from, id);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().transferFrom(from, to, id);

        assertEq(_token().getApproved(id), address(0));
        assertEq(_token().ownerOf(id), to);
        assertEq(_token().balanceOf(to), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testSafeTransferFromToEOA(uint256 id, address to) public {
        address from = address(0xABCD);

        if (to == address(0) || to == from) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        _token().mint(from, id);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, to, id);

        assertEq(_token().getApproved(id), address(0));
        assertEq(_token().ownerOf(id), to);
        assertEq(_token().balanceOf(to), 1);
        assertEq(_token().balanceOf(from), 0);
    }

    function testSafeTransferFromToERC721Recipient(uint256 id) public {
        address from = address(0xABCD);

        ERC721Recipient recipient = new ERC721Recipient();

        _token().mint(from, id);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, address(recipient), id);

        assertEq(_token().getApproved(id), address(0));
        assertEq(_token().ownerOf(id), address(recipient));
        assertEq(_token().balanceOf(address(recipient)), 1);
        assertEq(_token().balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(recipient.data(), "");
    }

    function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes calldata data) public {
        address from = address(0xABCD);
        ERC721Recipient recipient = new ERC721Recipient();

        _token().mint(from, id);

        vm.prank(from);
        _token().setApprovalForAll(address(this), true);

        _token().safeTransferFrom(from, address(recipient), id, data);

        assertEq(_token().getApproved(id), address(0));
        assertEq(_token().ownerOf(id), address(recipient));
        assertEq(_token().balanceOf(address(recipient)), 1);
        assertEq(_token().balanceOf(from), 0);

        assertEq(recipient.operator(), address(this));
        assertEq(recipient.from(), from);
        assertEq(recipient.id(), id);
        assertEq(recipient.data(), data);
    }

    function testSafeMintToEOA(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        if (uint256(uint160(to)) <= 18 || to.code.length > 0) return;

        _token().mint(to, id);

        assertEq(_token().ownerOf(id), address(to));
        assertEq(_token().balanceOf(address(to)), 1);
    }

    function testSafeMintToERC721Recipient(uint256 id) public {
        ERC721Recipient to = new ERC721Recipient();

        _token().mint(address(to), id);

        assertEq(_token().ownerOf(id), address(to));
        assertEq(_token().balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(to.data(), "");
    }

    function testSafeMintToERC721RecipientWithData(uint256 id, bytes calldata data) public {
        ERC721Recipient to = new ERC721Recipient();

        _token().mint(address(to), id, data);

        assertEq(_token().ownerOf(id), address(to));
        assertEq(_token().balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), id);
        assertEq(to.data(), data);
    }

    function testFailMintToZero(uint256 id) public {
        _token().mint(address(0), id);
    }

    function testFailDoubleMint(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        _token().mint(to, id);
        _token().mint(to, id);
    }

    function testFailBurnUnMinted(uint256 id) public {
        _token().burn(id);
    }

    function testFailDoubleBurn(uint256 id, address to) public {
        if (to == address(0)) to = address(0xBEEF);

        _token().mint(to, id);

        _token().burn(id);
        _token().burn(id);
    }

    function testFailApproveUnMinted(uint256 id, address to) public {
        _token().approve(to, id);
    }

    function testFailApproveUnAuthorized(
        address owner,
        uint256 id,
        address to
    ) public {
        if (owner == address(0) || owner == address(this)) owner = address(0xBEEF);

        _token().mint(owner, id);

        _token().approve(to, id);
    }

    function testFailTransferFromUnOwned(
        address from,
        address to,
        uint256 id
    ) public {
        _token().transferFrom(from, to, id);
    }

    function testFailTransferFromWrongFrom(
        address owner,
        address from,
        address to,
        uint256 id
    ) public {
        if (owner == address(0)) to = address(0xBEEF);
        if (from == owner) revert();

        _token().mint(owner, id);

        _token().transferFrom(from, to, id);
    }

    function testFailTransferFromToZero(uint256 id) public {
        _token().mint(address(this), id);

        _token().transferFrom(address(this), address(0), id);
    }

    function testFailTransferFromNotOwner(
        address from,
        address to,
        uint256 id
    ) public {
        if (from == address(this)) from = address(0xBEEF);

        _token().mint(from, id);

        _token().transferFrom(from, to, id);
    }

    function testFailSafeTransferFromToNonERC721Recipient(uint256 id) public {
        _token().mint(address(this), id);

        _token().safeTransferFrom(address(this), address(new NonERC721Recipient()), id);
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
        _token().mint(address(this), id);

        _token().safeTransferFrom(address(this), address(new NonERC721Recipient()), id, data);
    }

    function testFailSafeTransferFromToRevertingERC721Recipient(uint256 id) public {
        _token().mint(address(this), id);

        _token().safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id);
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
        _token().mint(address(this), id);

        _token().safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id, data);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData(uint256 id) public {
        _token().mint(address(this), id);

        _token().safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id);
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data)
        public
    {
        _token().mint(address(this), id);

        _token().safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id, data);
    }

    function testFailSafeMintToNonERC721Recipient(uint256 id) public {
        _token().mint(address(new NonERC721Recipient()), id);
    }

    function testFailSafeMintToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
        _token().mint(address(new NonERC721Recipient()), id, data);
    }

    function testFailSafeMintToRevertingERC721Recipient(uint256 id) public {
        _token().mint(address(new RevertingERC721Recipient()), id);
    }

    function testFailSafeMintToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
        _token().mint(address(new RevertingERC721Recipient()), id, data);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnData(uint256 id) public {
        _token().mint(address(new WrongReturnDataERC721Recipient()), id);
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data) public {
        _token().mint(address(new WrongReturnDataERC721Recipient()), id, data);
    }

    function testFailOwnerOfUnminted(uint256 id) public view {
        _token().ownerOf(id);
    }
}