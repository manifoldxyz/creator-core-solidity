object "DeploymentProxy" {
    // deployment code
    code {
        let size := datasize("runtime")
        datacopy(0, dataoffset("runtime"), size)
        return(0, size)
    }
    object "runtime" {
        // deployed code
        code {
            // Calldata encoded is:
            // nonce (bytes32), extensionArray (address[]), adminArray (address[]), bytecode
            // nonce is 32 bytes at location 0
            // extensionArray starts at location 32, and is of length 64 + length*32 (first byte is array data offset, second is array data length)
            // adminArray starts at 64 + extensionArrayLength*32, and is of length 64 + length*32 (first byte is array data offset, second is array data length)
            if iszero(eq(32, calldataload(32))) { revert(0, 0) }
            // Load array data
            let extensionArrayLength := calldataload(64)
            let adminArrayOffset := add(96, mul(extensionArrayLength, 32))
            if iszero(eq(32, calldataload(adminArrayOffset))) { revert(0, 0) }
            let adminArrayLength := calldataload(add(32, adminArrayOffset))
            // Compute bytecode offset
            let offset := add(160, mul(add(extensionArrayLength, adminArrayLength), 32))
            // Copy nonce + extensionArray + adminArray into position 0
            calldatacopy(0, 0, offset)
            let salt := keccak256(0, offset)
            // Copy bytecode without nonce + extensionArray + adminArray into position 0
            calldatacopy(0, offset, sub(calldatasize(), offset))
            // Create2, using the bytecode stored in memory from the prior line
            let result := create2(callvalue(), 0, sub(calldatasize(), offset), salt)
            if iszero(result) { revert(0, 0) }
            // Store function selector for registerExtension(address,string)
            for { let i } lt(i, extensionArrayLength) { i := add(i, 1) } {
                mstore(0, 0x3071a0f9)
                // Store the extension
                calldatacopy(32, add(96, mul(i, 32)), 32)
                // Store empty string
                mstore(64, 64)
                mstore(96, 0)
                let extensionRegisterResult := call(gas(), result, 0, 28, 100, 0, 0)
                if iszero(extensionRegisterResult) { revert(0, 0) }
            }
            // Store function selector for approveAdmin(address)
            let adminArrayDataOffset := add(64, adminArrayOffset)
            for { let i } lt(i, adminArrayLength) { i := add(i, 1) } {
                mstore(0, 0x6d73e669)
                // Store the admin address
                calldatacopy(32, add(adminArrayDataOffset, mul(i, 32)), 32)
                // Store empty string
                mstore(64, 64)
                mstore(96, 0)
                let approveAdminResult := call(gas(), result, 0, 28, 36, 0, 0)
                if iszero(approveAdminResult) { revert(0, 0) }
            }
            // Store function selector for transferOwnership(address)
            mstore(0, 0xf2fde38b)
            // Store the caller
            mstore(32, caller())
            // Call transferOwnership(caller())
            let transfer := call(gas(), result, 0, 28, 36, 0, 0)
            if iszero(transfer) { revert(0, 0) }
            // Store address
            mstore(0, result)
            // Emit event
            let signatureHash := 0x4db17dd5e4732fb6da34a148104a592783ca119a1e7bb8829eba6cbadef0b511
            log1(0, 32, signatureHash)
            return(12, 20)
        }
    }
}