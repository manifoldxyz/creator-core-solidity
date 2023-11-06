// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract YulDeployer is Test {
    ///@notice Compiles a Yul contract and returns the address that the contract was deployed to
    ///@notice If deployment fails, an error will be thrown
    ///@param fileName - The file name of the Yul contract. For example, the file name for "Example.yul" is "Example"
    ///@return deployedAddress - The address that the contract was deployed to
    function deployContract(string memory fileName) public returns (address) {
        string memory bashCommand = string.concat('cast abi-encode "f(bytes)" $(solc --strict-assembly ', string.concat(fileName, " --bin | tail -1)"));

        string[] memory inputs = new string[](3);
        inputs[0] = "bash";
        inputs[1] = "-c";
        inputs[2] = bashCommand;

        bytes memory bytecode = abi.decode(vm.ffi(inputs), (bytes));
        // TODO: This is the bytecode from DeploymentProxy.yul. For some reason the above method for solc compile does not work:
        // See: https://github.com/CodeForcer/foundry-yul/issues/6
        bytecode = hex"606380600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b63f2fde38b82523360205281826024601c85855af115156057578182fd5b8082525050506014600cf3";

        ///@notice deploy the bytecode with the create instruction
        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        ///@notice check that the deployment was successful
        require(
            deployedAddress != address(0),
            "YulDeployer could not deploy contract"
        );

        ///@notice return the address that the contract was deployed to
        return deployedAddress;
    }
}