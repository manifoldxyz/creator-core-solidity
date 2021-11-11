const truffleAssert = require('truffle-assertions');

const ERC721Creator = artifacts.require("ERC721Creator");
const ERC721CreatorEnumerable = artifacts.require("ERC721CreatorEnumerable");
const MockERC721CreatorExtensionBurnable = artifacts.require("MockERC721CreatorExtensionBurnable");
const MockERC721CreatorExtensionOverride = artifacts.require("MockERC721CreatorExtensionOverride");
const MockERC721CreatorMintPermissions = artifacts.require("MockERC721CreatorMintPermissions");
const MockContract = artifacts.require("MockContract");

contract('ERC721Creator', function ([minter_account, ...accounts]) {
    const name = 'Token';
    const symbol = 'NFT';
    const minter = minter_account;
    const [
           owner,
           newOwner,
           another,
           anyone,
           ] = accounts;

    it('creator gas', async function () {
        const creatorGasEstimate = await ERC721Creator.new.estimateGas(name, symbol, {from:owner});
        console.log("ERC721Creator gas estimate: %s", creatorGasEstimate);
        const creatorEnumerableGasEstimate = await ERC721CreatorEnumerable.new.estimateGas(name, symbol, {from:owner});
        console.log("ERC721CreatorEnumerable gas estimate: %s", creatorEnumerableGasEstimate);
    });

    describe('ERC721CreatorEnumerable', function() {
        var creator;

        beforeEach(async function () {
            creator = await ERC721CreatorEnumerable.new(name, symbol, {from:owner});
        });

        it('creator enumerable extension override test', async function () {
            var extension = await MockERC721CreatorExtensionOverride.new(creator.address, {from:owner});
            await creator.registerExtension(extension.address, 'http://extension/', {from:owner});
            // Test legacy interface support
            assert.equal(true, await extension.supportsInterface('0x7005caad'));
            assert.equal(true, await extension.supportsInterface('0x99cdaa22'));

            await extension.testMint(anyone);
            var tokenId = 1;
            await creator.transferFrom(anyone, another, tokenId, {from:anyone});
            await truffleAssert.reverts(extension.setApproveTransfer(creator.address, true, {from:anyone}), "AdminControl: Must be owner or admin");
            await extension.setApproveTransfer(creator.address, true, {from:owner});
            await truffleAssert.reverts(creator.transferFrom(another, anyone, tokenId, {from:another}), "Extension approval failure");
            await extension.setApproveEnabled(true);
            await creator.transferFrom(another, anyone, tokenId, {from:another});

            await extension.setTokenURI('override');
            assert.equal(await creator.tokenURI(tokenId), 'override');
        });

        it('creator enumerable blacklist extension test', async function() {
            await truffleAssert.reverts(creator.blacklistExtension(creator.address, {from:owner}), "Cannot blacklist yourself");
            await creator.blacklistExtension(anyone, {from:owner});
            await truffleAssert.reverts(creator.totalSupplyExtension(anyone), "Extension blacklisted");
            await truffleAssert.reverts(creator.tokenByIndexExtension(anyone, 1), "Extension blacklisted");
            await truffleAssert.reverts(creator.balanceOfExtension(anyone, another), "Extension blacklisted");
            await truffleAssert.reverts(creator.tokenOfOwnerByIndexExtension(anyone, another, 1), "Extension blacklisted");

            const extension1 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            await creator.blacklistExtension(extension1.address, {from:owner});
            await truffleAssert.reverts(creator.registerExtension(extension1.address, 'http://extension1', {from:owner}), "Extension blacklisted");

            const extension2 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:owner});
            await extension2.testMint(anyone);
            let newTokenId = (await extension2.mintedTokens()).slice(-1)[0];
            await creator.tokenURI(newTokenId);
            await creator.tokenExtension(newTokenId);
            await creator.blacklistExtension(extension2.address, {from:owner});
            await truffleAssert.reverts(creator.tokenURI(newTokenId), "Extension blacklisted");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId), "Extension blacklisted");
            
        });

        it('creator enumerable access test', async function () {
            await truffleAssert.reverts(creator.tokenByIndexExtension(anyone, 1), "Index out of bounds");
            await truffleAssert.reverts(creator.tokenOfOwnerByIndexExtension(anyone, anyone, 1), "Index out of bounds");
        });

        it('creator enumerable functionality test', async function () {
            assert.equal((await creator.getExtensions()).length, 0);

            await creator.setBaseTokenURI("http://base/", {from:owner});

            const extension1 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 0);
            await truffleAssert.reverts(extension1.onBurn(anyone, 1), "Can only be called by token creator");

            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            
            const extension2 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 1);

            // Admins can register extensions
            await creator.approveAdmin(another, {from:owner});
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:another});
            assert.equal((await creator.getExtensions()).length, 2);

            // Minting cost
            const mintBase = await creator.mintBase.estimateGas(anyone, {from:owner});
            console.log("No Extension mint gas estimate: %s", mintBase);
            const mintGasEstimate = await extension1.testMint.estimateGas(anyone);
            console.log("Extension mint gas estimate: %s", mintGasEstimate);

            // Test minting
            await extension1.testMint(anyone);
            let newTokenId1 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 1);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 1);
            assert.equal(await creator.balanceOfExtension(extension1.address, owner), 0);
            assert.equal(await creator.balanceOfExtension(extension1.address, anyone), 1);
            assert.equal(await creator.tokenExtension(newTokenId1), extension1.address);

            await extension1.testMint(another);
            let newTokenId2 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 2);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 2);
            assert.equal(await creator.balanceOfExtension(extension1.address, owner), 0);
            assert.equal(await creator.balanceOfExtension(extension1.address, anyone), 1);
            assert.equal(await creator.balanceOfExtension(extension1.address, another), 1);

            await extension2.testMint(anyone);
            let newTokenId3 = (await extension2.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 3);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 2);
            assert.equal(await creator.totalSupplyExtension(extension2.address), 1);
            assert.equal(await creator.balanceOfExtension(extension1.address, owner), 0);
            assert.equal(await creator.balanceOfExtension(extension1.address, anyone), 1);
            assert.equal(await creator.balanceOfExtension(extension1.address, another), 1);
            assert.equal(await creator.balanceOfExtension(extension2.address, anyone), 1);

            await extension1.testMint(anyone);
            let newTokenId4 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 4);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 3);
            assert.equal(await creator.balanceOfExtension(extension1.address, owner), 0);
            assert.equal(await creator.balanceOfExtension(extension1.address, anyone), 2);
            assert.equal(await creator.balanceOfExtension(extension1.address, another), 1);
            assert.equal(await creator.balanceOfExtension(extension2.address, anyone), 1);

            await extension1.testMint(anyone);
            let newTokenId5 = (await extension1.mintedTokens()).slice(-1)[0];
            assert.equal(await creator.totalSupply(), 5);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 4);
            assert.equal(await creator.balanceOfExtension(extension1.address, owner), 0);
            assert.equal(await creator.balanceOfExtension(extension1.address, anyone), 3);
            assert.equal(await creator.balanceOfExtension(extension1.address, another), 1);
            assert.equal(await creator.balanceOfExtension(extension2.address, anyone), 1);

            await creator.mintBase(anyone, {from:owner});
            assert.equal(await creator.totalSupply(), 6);
            assert.equal(await creator.totalSupplyBase(), 1);
            assert.equal(await creator.balanceOfBase(anyone), 1);
            let newTokenId6 = await creator.tokenByIndexBase(0);
            assert.deepEqual(newTokenId6, await creator.tokenOfOwnerByIndexBase(anyone, 0));
            await truffleAssert.reverts(creator.tokenExtension(newTokenId6), "No extension for token");

            // Check URI's
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId3), 'http://extension2/'+newTokenId3);
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.tokenURI(newTokenId5), 'http://extension1/'+newTokenId5);
            assert.equal(await creator.tokenURI(newTokenId6), 'http://base/'+newTokenId6);

            // Removing extension should prevent further access
            await creator.unregisterExtension(extension1.address, {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            await truffleAssert.reverts(extension1.testMint(anyone), "Must be registered extension");

            // URI's should still be ok, tokens should still exist
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.tokenURI(newTokenId5), 'http://extension1/'+newTokenId5);
            assert.equal(await creator.totalSupply(), 6);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 4);

            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 0), newTokenId1);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 1), newTokenId2);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 2), newTokenId4);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 3), newTokenId5);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 0), newTokenId1);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 1), newTokenId4);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 2), newTokenId5);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, another, 0), newTokenId2);

            // Burning
            await truffleAssert.reverts(creator.burn(newTokenId1, {from:another}), "Caller is not owner nor approved");
            await creator.burn(newTokenId1, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");
            assert.equal(await creator.totalSupply(), 5);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 3);
            assert.equal(await creator.balanceOfExtension(extension1.address, owner), 0);
            assert.equal(await creator.balanceOfExtension(extension1.address, anyone), 2);
            assert.equal(await creator.balanceOfExtension(extension2.address, anyone), 1);
            assert.equal(await creator.balanceOfExtension(extension1.address, another), 1);
            // Index shift after burn
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 0), newTokenId5);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 1), newTokenId2);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 2), newTokenId4);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 0), newTokenId5);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 1), newTokenId4);
            // Check burn callback
            assert.equal(await extension1.burntTokens(), 1);
            assert.deepEqual((await extension1.burntTokens()).slice(-1)[0], newTokenId1);

            // Transfer
            await creator.transferFrom(anyone, another, newTokenId4, {from:anyone});
            assert.equal(await creator.balanceOfExtension(extension1.address, anyone), 1);
            assert.equal(await creator.balanceOfExtension(extension2.address, anyone), 1);
            assert.equal(await creator.balanceOfExtension(extension1.address, another), 2);
            // Index shift after transfer
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 0), newTokenId5);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 1), newTokenId2);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 2), newTokenId4);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 0), newTokenId5);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, another, 0), newTokenId2);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, another, 1), newTokenId4);

            await creator.burn(newTokenId6, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId6), "Nonexistent token");
            assert.equal(await creator.totalSupply(), 4);
            assert.equal(await creator.totalSupplyBase(), 0);
            assert.equal(await creator.balanceOfBase(owner), 0);
        });

        it('creator enumerable permissions functionality test', async function () {
            const extension1 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            
            const extension2 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:owner});

            await truffleAssert.reverts(MockERC721CreatorMintPermissions.new(anyone), "Must implement IERC721Creator");
            const permissions = await MockERC721CreatorMintPermissions.new(creator.address);
            await truffleAssert.reverts(permissions.approveMint(anyone, anyone, 1), "Can only be called by token creator");
            
            await truffleAssert.reverts(creator.setMintPermissions(extension1.address, anyone, {from:owner}), "Invalid address");
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

        it('creator enumerable royalites update test', async function () {
            await truffleAssert.reverts(creator.getRoyalties(1), "Nonexistent token");
            await truffleAssert.reverts(creator.methods['setRoyalties(uint256,address[],uint256[])'](1,[anyone],[123], {from:owner}), "Nonexistent token");

            await creator.mintBase(anyone, {from:owner});
            var tokenId1 = 1;
            var results;

            // No royalties
            results = await creator.getRoyalties(tokenId1);
            assert.equal(results[0].length, 0);
            assert.equal(results[1].length, 0);

            await truffleAssert.reverts(creator.methods['setRoyalties(uint256,address[],uint256[])'](tokenId1,[anyone,another],[9999,1], {from:owner}), "Invalid total royalties");
            await truffleAssert.reverts(creator.methods['setRoyalties(uint256,address[],uint256[])'](tokenId1,[anyone],[1,2], {from:owner}), "Invalid input");
            await truffleAssert.reverts(creator.methods['setRoyalties(uint256,address[],uint256[])'](tokenId1,[anyone,another],[1], {from:owner}), "Invalid input");
            
            // Set token royalties
            await creator.methods['setRoyalties(uint256,address[],uint256[])'](tokenId1,[anyone,another],[123,456],{from:owner});
            results = await creator.getRoyalties(tokenId1);
            assert.equal(results[0].length, 2);
            assert.equal(results[1].length, 2);

            const extension = await MockERC721CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension.address, 'http://extension/', {from:owner});
            await extension.testMint(anyone);
            var tokenId2 = 2;

            // No royalties
            results = await creator.getRoyalties(tokenId2);
            assert.equal(results[0].length, 0);
            assert.equal(results[1].length, 0);

            await truffleAssert.reverts(creator.methods['setRoyaltiesExtension(address,address[],uint256[])'](extension.address,[anyone,another],[9999,1], {from:owner}), "Invalid total royalties");
            await truffleAssert.reverts(creator.methods['setRoyaltiesExtension(address,address[],uint256[])'](extension.address,[anyone],[1,2], {from:owner}), "Invalid input");
            await truffleAssert.reverts(creator.methods['setRoyaltiesExtension(address,address[],uint256[])'](extension.address,[anyone,another],[1], {from:owner}), "Invalid input");
            
            // Set royalties
            await creator.methods['setRoyaltiesExtension(address,address[],uint256[])'](extension.address,[anyone],[123], {from:owner});
            results = await creator.getRoyalties(tokenId2);
            assert.equal(results[0].length, 1);
            assert.equal(results[1].length, 1);

            await creator.mintBase(anyone, {from:owner});
            var tokenId3 = 3;
            await extension.testMint(anyone);
            var tokenId4 = 4;
            results = await creator.getRoyalties(tokenId3);
            assert.equal(results[0].length, 0);
            assert.equal(results[1].length, 0);
            results = await creator.getRoyalties(tokenId4);
            assert.equal(results[0].length, 1);
            assert.equal(results[1].length, 1);
            
            // Set default royalties
            await truffleAssert.reverts(creator.methods['setRoyalties(address[],uint256[])']([anyone,another],[9999,1], {from:owner}), "Invalid total royalties");
            await truffleAssert.reverts(creator.methods['setRoyalties(address[],uint256[])']([anyone],[1,2], {from:owner}), "Invalid input");
            await truffleAssert.reverts(creator.methods['setRoyalties(address[],uint256[])']([anyone,another],[1], {from:owner}), "Invalid input");
            await creator.methods['setRoyalties(address[],uint256[])']([another],[456], {from:owner});
            results = await creator.getRoyalties(tokenId1);
            assert.equal(results[0].length, 2);
            assert.equal(results[1].length, 2);
            results = await creator.getRoyalties(tokenId2);
            assert.equal(results[0].length, 1);
            assert.equal(results[1].length, 1);
            assert.equal(results[0],anyone);
            results = await creator.getRoyalties(tokenId3);
            assert.equal(results[0].length, 1);
            assert.equal(results[1].length, 1);
            assert.equal(results[0][0],another);
            results = await creator.getRoyalties(tokenId4);
            assert.equal(results[0].length, 1);
            assert.equal(results[1].length, 1);
            assert.equal(results[0][0],anyone);
            
            // Unset royalties
            await creator.methods['setRoyalties(address[],uint256[])']([],[], {from:owner});
            results = await creator.getRoyalties(tokenId3);
            assert.equal(results[0].length, 0);
            assert.equal(results[1].length, 0);
            results = await creator.getRoyalties(tokenId4);
            assert.equal(results[0].length, 1);
            assert.equal(results[1].length, 1);
            assert.equal(results[0][0],anyone);
            await creator.methods['setRoyaltiesExtension(address,address[],uint256[])'](extension.address,[],[], {from:owner});
            results = await creator.getRoyalties(tokenId4);
            assert.equal(results[0].length, 0);
            assert.equal(results[1].length, 0);
        });

    });

});