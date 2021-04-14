const truffleAssert = require('truffle-assertions');

const ERC721Creator = artifacts.require("ERC721Creator");
const MockERC721CreatorExtension = artifacts.require("MockERC721CreatorExtension");
const MockContract = artifacts.require("MockContract");

contract('ERC721Creator', function ([creator, ...accounts]) {
    const name = 'Token';
    const symbol = 'NFT';
    const minter = creator;
    const [
           owner,
           newOwner,
           another,
           anyone,
           ] = accounts;

    describe('ERC721Creator', function() {
        var creator;

        beforeEach(async function () {
            creator = await ERC721Creator.new(name, symbol, {from:owner});
        });

        it('creator permission test', async function () {
            await truffleAssert.reverts(creator.registerExtension(anyone, 'http://extension', {from:anyone}), "AdminControl: Must be the contract owner or admin to call this function");
            await truffleAssert.reverts(creator.unregisterExtension(anyone, {from:anyone}), "AdminControl: Must be the contract owner or admin to call this function");
            await truffleAssert.reverts(creator.setBaseTokenURI('http://extension', {from:anyone}), "ERC721Creator: Must be a registered extension to call this function");
            await truffleAssert.reverts(creator.setTokenURI(1, 'http://extension', {from:anyone}), "ERC721Creator: Must be a registered extension to call this function");
            await truffleAssert.reverts(creator.mint(anyone, {from:anyone}), "ERC721Creator: Must be a registered extension to call this function");
        });

        it('extension functionality test', async function () {
            assert.equal((await creator.getExtensions()).length, 0);

            const extension1 = await MockERC721CreatorExtension.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 0);

            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            
            const extension2 = await MockERC721CreatorExtension.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 1);

            // Admins can register extensions
            await creator.approveAdmin(another, {from:owner});
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:another});
            assert.equal((await creator.getExtensions()).length, 2);

            // Prevents registration of bad extensions
            const badExtension = await MockContract.new();
            await truffleAssert.reverts(creator.registerExtension(badExtension.address, 'http://badextension/', {from:owner}), "ERC721Creator: Must implement IERC721CreatorExtension");

            // Test minting
            await extension1.testMint(anyone);
            let newTokenId1 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 1);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 1);

            await extension1.testMint(anyone);
            let newTokenId2 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 2);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 2);

            await extension2.testMint(anyone);
            let newTokenId3 = (await extension2.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 3);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 2);
            assert.equal(await creator.totalSupplyOfExtension(extension2.address), 1);

            // Check URI's
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId3), 'http://extension2/'+newTokenId3);

            // Removing extension should prevent further access
            await creator.unregisterExtension(extension1.address, {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            await truffleAssert.reverts(extension1.testMint(anyone), "ERC721Creator: Must be a registered extension to call this function");

            // URI's should still be ok, tokens should still exist
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.totalSupply(), 3);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 2);

            assert.equal(await creator.tokenByIndexOfExtension(extension1.address, 0) - newTokenId1, 0);
            assert.equal(await creator.tokenByIndexOfExtension(extension1.address, 1) - newTokenId2, 0);

            // Burning
            await creator.burn(newTokenId1, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");
            assert.equal(await creator.totalSupply(), 2);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 1);
            // Check burn callback
            assert.equal(await extension1.burntTokens(), 1);
            assert.equal((await extension1.burntTokens()).slice(-1)[0] - newTokenId1, 0);
            
        });
    });

});