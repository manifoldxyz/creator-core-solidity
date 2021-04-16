const truffleAssert = require('truffle-assertions');

const NFT2ERC20 = artifacts.require("NFT2ERC20");
const MockERC721 = artifacts.require("MockERC721");
const MockERC1155 = artifacts.require("MockERC1155");
const MockNFT2ERC20RateEngine = artifacts.require("MockNFT2ERC20RateEngine");

contract('NFT2ERC20', function ([creator, ...accounts]) {
    const name = 'Token';
    const symbol = 'NFT';
    const minter = creator;
    const [
           owner,
           newOwner,
           another,
           anyone,
           ] = accounts;

    describe('NFT2ERC20', function() {
        var token;
        var mock721;
        var mock1155;

        beforeEach(async function () {
            token = await NFT2ERC20.new(name, symbol, {from:owner});
            mock721 = await MockERC721.new('721', '721', {from:owner});
            mock1155 = await MockERC1155.new('1155uri', {from:owner});
            mockRateEngine = await MockNFT2ERC20RateEngine.new();
        });

        it('access test', async function () {
            await truffleAssert.reverts(token.setRateEngine(anyone, {from:anyone}), "AdminControl: Must be the contract owner or admin to call this function");
            await truffleAssert.reverts(token.setTransferFunction('erc721', '0x12345678', {from:anyone}), "AdminControl: Must be the contract owner or admin to call this function");
            await truffleAssert.reverts(token.setTreasury(another, 1000, {from:anyone}), "AdminControl: Must be the contract owner or admin to call this function");
        });

        it('functionality test', async function () {
            await mock721.testMint(another, 721);
            assert.equal(await mock721.balanceOf(another), 1);
            
            await mock1155.testMint(another, 1155, 10, "0x0");
            assert.equal(await mock1155.balanceOf(another, 1155), 10);
            
            await truffleAssert.reverts(token.burnToken(mock721.address, [721], 'erc721'), "NFT2ERC20: Rate Engine not configured");

            await truffleAssert.reverts(token.setRateEngine(anyone, {from:owner}), "NFT2ERC20: Must implement INFT2ERC20RateEngine");

            token.setRateEngine(mockRateEngine.address, {from:owner});

            await truffleAssert.reverts(token.burnToken(mock721.address, [721], 'erc721'), "NFT2ERC20: Transfer function not defined for spec");

            await token.setTransferFunction('erc721', '0x23b872dd', {from:owner});

            await mock721.approve(token.address, 721, {from:another});
            await token.burnToken(mock721.address, [721], 'erc721', {from:another});
            assert.equal(await mock721.balanceOf(another), 0);
            assert.equal(await token.balanceOf(another), 10);

            await token.setTransferFunction('erc1155', '0xf242432a', {from:owner});
            await mock1155.setApprovalForAll(token.address, true, {from:another});

            let valuesArray = [1155, 2];
            // Add additional ints to fake empty bytes data necessary for ERC1155 safeTransferFrom
            // First element of an encoded byte array is a header which gives the 32-byte offset.  Second element is a blank value
            valuesArray.push((valuesArray.length+1)*32);
            valuesArray.push(0)
            
            await token.burnToken(mock1155.address, valuesArray, 'erc1155', {from:another});
            assert.equal(await mock1155.balanceOf(another, 1155), 8);
            assert.equal(await token.balanceOf(another), 20);
        });

        it('basis points test', async function () {
            await truffleAssert.reverts(token.setTreasury(anyone, 10001, {from:owner}), "NFT2ERC20:  basisPoints must be less than 10000 (100%)");
            await token.setTreasury(anyone, 1000, {from:owner});
            await mock721.testMint(another, 721);
            assert.equal(await mock721.balanceOf(another), 1);
            token.setRateEngine(mockRateEngine.address, {from:owner});
            await token.setTransferFunction('erc721', '0x23b872dd', {from:owner});
            await mock721.approve(token.address, 721, {from:another});
            await token.burnToken(mock721.address, [721], 'erc721', {from:another});
            assert.equal(await mock721.balanceOf(another), 0);
            assert.equal(await token.balanceOf(another), 10);
            assert.equal(await token.balanceOf(anyone), 1);
        });
    });

});