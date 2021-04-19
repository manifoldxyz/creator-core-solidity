const truffleAssert = require('truffle-assertions');

const ERC721Creator = artifacts.require("ERC721Creator");
const MockERC721CreatorExtension = artifacts.require("MockERC721CreatorExtension");
const MockERC721CreatorMintPermissions = artifacts.require("MockERC721CreatorMintPermissions");
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

    it('creator gas', async function () {
        const creatorGasEstimate = await ERC721Creator.new.estimateGas(name, symbol, {from:owner});
        console.log("ERC721Creator gas estimate: %s", creatorGasEstimate);
    });

    describe('ERC721Creator', function() {
        var creator;

        beforeEach(async function () {
            creator = await ERC721Creator.new(name, symbol, {from:owner});
        });

        it('creator permission test', async function () {
            await truffleAssert.reverts(creator.registerExtension(anyone, 'http://extension', {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.unregisterExtension(anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setBaseTokenURI('http://extension', {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.setTokenURI(1, 'http://extension', {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.setMintPermissions(anyone, anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.mint(anyone, {from:anyone}), "ERC721Creator: Must be registered extension");
        });

        it('creator access test', async function () {
            await truffleAssert.reverts(creator.tokenByIndexOfExtension(anyone, 1), "ERC721Creator: Index out of bounds");
            await truffleAssert.reverts(creator.extensionTokenOfOwnerByIndex(anyone, anyone, 1), "ERC721Creator: Index out of bounds");
        });

        it('extension functionality test', async function () {
            assert.equal((await creator.getExtensions()).length, 0);

            await truffleAssert.reverts(MockERC721CreatorExtension.new(anyone), "ERC721CreatorExtension: Must implement IERC721Creator");

            const extension1 = await MockERC721CreatorExtension.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 0);
            await truffleAssert.reverts(extension1.onBurn(anyone, 1), "ERC721CreatorExtension: Can only be called by token creator");

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

            // Minting cost
            const mintGasEstimate = await extension1.testMint.estimateGas(anyone);
            console.log("Extension mint gas estimate: %s", mintGasEstimate);

            // Test minting
            await extension1.testMint(anyone);
            let newTokenId1 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 1);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 1);
            assert.equal(await creator.extensionBalanceOf(extension1.address, owner), 0);
            assert.equal(await creator.extensionBalanceOf(extension1.address, anyone), 1);
            assert.equal(await creator.tokenExtension(newTokenId1), extension1.address);

            await extension1.testMint(another);
            let newTokenId2 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 2);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 2);
            assert.equal(await creator.extensionBalanceOf(extension1.address, owner), 0);
            assert.equal(await creator.extensionBalanceOf(extension1.address, anyone), 1);
            assert.equal(await creator.extensionBalanceOf(extension1.address, another), 1);

            await extension2.testMint(anyone);
            let newTokenId3 = (await extension2.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 3);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 2);
            assert.equal(await creator.totalSupplyOfExtension(extension2.address), 1);
            assert.equal(await creator.extensionBalanceOf(extension1.address, owner), 0);
            assert.equal(await creator.extensionBalanceOf(extension1.address, anyone), 1);
            assert.equal(await creator.extensionBalanceOf(extension1.address, another), 1);
            assert.equal(await creator.extensionBalanceOf(extension2.address, anyone), 1);

            await extension1.testMint(anyone);
            let newTokenId4 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 4);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 3);
            assert.equal(await creator.extensionBalanceOf(extension1.address, owner), 0);
            assert.equal(await creator.extensionBalanceOf(extension1.address, anyone), 2);
            assert.equal(await creator.extensionBalanceOf(extension1.address, another), 1);
            assert.equal(await creator.extensionBalanceOf(extension2.address, anyone), 1);


            // Check URI's
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId3), 'http://extension2/'+newTokenId3);
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);

            // Removing extension should prevent further access
            await creator.unregisterExtension(extension1.address, {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            await truffleAssert.reverts(extension1.testMint(anyone), "ERC721Creator: Must be registered extension");

            // URI's should still be ok, tokens should still exist
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.totalSupply(), 4);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 3);

            assert.equal(await creator.tokenByIndexOfExtension(extension1.address, 0) - newTokenId1, 0);
            assert.equal(await creator.tokenByIndexOfExtension(extension1.address, 1) - newTokenId2, 0);
            assert.equal(await creator.tokenByIndexOfExtension(extension1.address, 2) - newTokenId4, 0);
            assert.equal(await creator.extensionTokenOfOwnerByIndex(extension1.address, anyone, 0) - newTokenId1, 0);
            assert.equal(await creator.extensionTokenOfOwnerByIndex(extension1.address, anyone, 1) - newTokenId4, 0);
            assert.equal(await creator.extensionTokenOfOwnerByIndex(extension1.address, another, 0) - newTokenId2, 0);

            // Burning
            await creator.burn(newTokenId1, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");
            assert.equal(await creator.totalSupply(), 3);
            assert.equal(await creator.totalSupplyOfExtension(extension1.address), 2);
            assert.equal(await creator.extensionBalanceOf(extension1.address, owner), 0);
            assert.equal(await creator.extensionBalanceOf(extension1.address, anyone), 1);
            assert.equal(await creator.extensionBalanceOf(extension2.address, anyone), 1);
            assert.equal(await creator.extensionBalanceOf(extension1.address, another), 1);
            // Index shift after burn
            assert.equal(await creator.tokenByIndexOfExtension(extension1.address, 0) - newTokenId4, 0);
            assert.equal(await creator.tokenByIndexOfExtension(extension1.address, 1) - newTokenId2, 0);
            assert.equal(await creator.extensionTokenOfOwnerByIndex(extension1.address, anyone, 0) - newTokenId4, 0);
            // Check burn callback
            assert.equal(await extension1.burntTokens(), 1);
            assert.equal((await extension1.burntTokens()).slice(-1)[0] - newTokenId1, 0);
            
        });

        it('permissions functionality test', async function () {
            const extension1 = await MockERC721CreatorExtension.new(creator.address);
            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            
            const extension2 = await MockERC721CreatorExtension.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:owner});

            await truffleAssert.reverts(MockERC721CreatorMintPermissions.new(anyone), "ERC721CreatorMintPermissions: Must implement IERC721Creator");
            const permissions = await MockERC721CreatorMintPermissions.new(creator.address);
            await truffleAssert.reverts(permissions.approveMint(anyone, 1, anyone), "ERC721CreatorMintPermissions: Can only be called by token creator");
            
            await truffleAssert.reverts(creator.setMintPermissions(extension1.address, anyone, {from:owner}), "ERC721Creator: Invalid address");
            await creator.setMintPermissions(extension1.address, permissions.address, {from:owner});
            
            await extension1.testMint(anyone);
            await extension2.testMint(anyone);

            permissions.setApproveEnabled(false);
            await truffleAssert.reverts(extension1.testMint(anyone), "MockERC721CreatorMintPermissions: Disabled");
            await extension2.testMint(anyone);

            await creator.setMintPermissions(extension1.address, '0x0000000000000000000000000000000000000000', {from:owner});
            await extension1.testMint(anyone);
            await extension2.testMint(anyone);
        });
    });

});