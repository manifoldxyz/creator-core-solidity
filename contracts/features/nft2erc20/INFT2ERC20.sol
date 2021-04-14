// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../../access/IAdminControl.sol";

interface INFT2ERC20 is IAdminControl, IERC20 {

    /*
     * @dev sets the contract used to get NFT to ERC20 conversion rate values
     */
    function setRateEngine(address rateEngine) external;

    /*
     * @dev sets the transfer function of a given spec
     */
    function setTransferFunction(string calldata spec, bytes4 transferFunction) external;

    /*
     * @dev burns an NFT token and gives the caller ERC20
     */
    function burnToken(address tokenContract, uint256[] calldata values, string calldata spec) external;

    
}