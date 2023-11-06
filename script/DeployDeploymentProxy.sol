// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../contracts/ERC721CreatorImplementation.sol";

contract DeployDeploymentProxy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // Salt is: 0x6d616e69666f6c6420636f6e7472616374206465706c6f7965722070726f7879
        // Hex of "manifold contract deployer proxy"
        bytes memory bytecode = abi.decode(vm.parseJson(vm.readFile("out/DeploymentProxy.yul/DeploymentProxy.json"), "$.bytecode.object"), (bytes));
        bytes memory initcode = abi.encodePacked(bytes32(0x6d616e69666f6c6420636f6e7472616374206465706c6f7965722070726f7879), bytecode);
        (bool success, bytes memory data) = address(0x4e59b44847b379578588920cA78FbF26c0B4956C).call(initcode);
        require(success, "DeploymentProxy deployment failed");
        address deployedAddress = address(uint160(bytes20(data)));
        console.logString("Deployed to:");
        console.logAddress( deployedAddress);
        vm.stopBroadcast();
    }
}
