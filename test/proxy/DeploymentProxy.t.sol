// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC721CreatorImplementation} from "creator-core/ERC721CreatorImplementation.sol";
import {ERC165Checker} from "openzeppelin/utils/introspection/ERC165Checker.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {Test} from "forge-std/Test.sol";
import {Proxy} from "openzeppelin/proxy/Proxy.sol";
import {Address} from "openzeppelin/utils/Address.sol";
import {StorageSlot} from "openzeppelin/utils/StorageSlot.sol";
import "./lib/YulDeployer.sol";

contract ProxyMock is Proxy {
    constructor(address impl) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = impl;
        (bool success, ) = impl.delegatecall(abi.encodeWithSignature("initialize(string,string)", "Test Proxy", "TP"));
        require(success, "Initialization failed");
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    
}

interface DeploymentProxy {}

contract DeploymentProxyTest is Test {
    DeploymentProxy proxy;
    ProxyMock proxyMock;
    address implementation;

    YulDeployer yulDeployer = new YulDeployer();
    address creator = address(0xC12EA7012);

    function setUp() public virtual {
        proxy = DeploymentProxy(yulDeployer.deployContract("out/DeploymentProxy.yul/DeploymentProxy.json"));
        implementation = address(new ERC721CreatorImplementation());
    }

    function testDeploy() public {
        vm.prank(creator);
        bytes32 salt = 0x0;
        bytes memory bytecode = abi.encodePacked(salt, vm.getCode("DeploymentProxy.t.sol:ProxyMock"), abi.encode(implementation));
        (bool success, bytes memory data) = address(proxy).call(bytecode);
        assertTrue(success);
        address deployedAddress = address(uint160(bytes20(data)));
        address contractOwner = ERC721CreatorImplementation(deployedAddress).owner();
        assertEq(creator, contractOwner);
    }
}
