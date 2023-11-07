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
      // Copy bytecode without salt into position 0
			calldatacopy(0, 32, sub(calldatasize(), 32))
      // Create2, using the bytecode stored in memory from the prior line, and loading the salt from calldata
			let result := create2(callvalue(), 0, sub(calldatasize(), 32), calldataload(0))
			if iszero(result) { revert(0, 0) }
      // Store function selector for transferOwnership(address)
      mstore(0, 0xf2fde38b)
			// Store the caller
			mstore(add(0, 0x20), caller())
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