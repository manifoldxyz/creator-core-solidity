const truffleAssert = require('truffle-assertions');

const ERC721Creator = artifacts.require("ERC721Creator");
const ERC721CreatorEnumerable = artifacts.require("ERC721CreatorEnumerable");
const MockERC721CreatorExtension = artifacts.require("MockERC721CreatorExtension");
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

    describe('ERC721Creator', function() {
        var creator;

        beforeEach(async function () {
            creator = await ERC721Creator.new(name, symbol, {from:owner});
        });

        it('creator permission test', async function () {
            await truffleAssert.reverts(creator.registerExtension(anyone, 'http://extension', {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.registerExtension(anyone, 'http://extension', true), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.unregisterExtension(anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.blacklistExtension(anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setBaseTokenURIExtension('http://extension', {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.setBaseTokenURIExtension('http://extension', true), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.setTokenURIPrefixExtension('http://extension', {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.methods['setTokenURIExtension(uint256,string)'](1, 'http://extension', {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.methods['setTokenURIExtension(uint256[],string[])']([1], ['http://extension'], {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.setBaseTokenURI('http://base', {from:anyone}),"AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setTokenURIPrefix('http://base', {from:anyone}),"AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256,string)'](1, 'http://base', {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256[],string[])']([1], ['http://base'], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setMintPermissions(anyone, anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintBase(address)'](anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintBase(address,string)'](anyone, "", {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintBaseBatch(address,uint16)'](anyone, 1, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintBaseBatch(address,string[])'](anyone, [""], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintExtension(address)'](anyone, {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.methods['mintExtension(address,string)'](anyone, "", {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.methods['mintExtensionBatch(address,uint16)'](anyone, 1, {from:anyone}), "ERC721Creator: Must be registered extension");
            await truffleAssert.reverts(creator.methods['mintExtensionBatch(address,string[])'](anyone, [""], {from:anyone}), "ERC721Creator: Must be registered extension");
        });
        
        it('creator blacklist extension test', async function() {
            await truffleAssert.reverts(creator.blacklistExtension(creator.address, {from:owner}), "RC721Creator: Cannot blacklist yourself");
            await creator.blacklistExtension(anyone, {from:owner});

            const extension1 = await MockERC721CreatorExtension.new(creator.address);
            await creator.blacklistExtension(extension1.address, {from:owner});
            await truffleAssert.reverts(creator.registerExtension(extension1.address, 'http://extension1', {from:owner}), "ERC721Creator: Extension blacklisted");

            const extension2 = await MockERC721CreatorExtension.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:owner});
            await extension2.testMint(anyone);
            let newTokenId = (await extension2.mintedTokens()).slice(-1)[0];
            await creator.tokenURI(newTokenId);
            await creator.tokenExtension(newTokenId);
            await creator.blacklistExtension(extension2.address, {from:owner});
            await truffleAssert.reverts(creator.tokenURI(newTokenId), "ERC721Creator: Extension blacklisted");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId), "ERC721Creator: Extension blacklisted");
        });

        it('creator functionality test', async function () {
            assert.equal((await creator.getExtensions()).length, 0);

            await creator.setBaseTokenURI("http://base/", {from:owner});

            const extension1 = await MockERC721CreatorExtension.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 0);
            await truffleAssert.reverts(extension1.onBurn(anyone, 1), "ERC721CreatorExtensionBurnable: Can only be called by token creator");

            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            
            const extension2 = await MockERC721CreatorExtension.new(creator.address);
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
            let newTokenId1 = 1;
            assert.equal(await creator.tokenExtension(newTokenId1), extension1.address);

            await extension1.testMint(another);
            let newTokenId2 = 2;

            await extension2.testMint(anyone);
            let newTokenId3 = 3;

            await extension1.testMint(anyone);
            let newTokenId4 = 4;

            await extension1.testMint(anyone, "extension5");
            let newTokenId5 = 5;

            await creator.methods['mintBase(address)'](anyone, {from:owner});
            let newTokenId6 = 6;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId6), "ERC721Creator: No extension");

            await creator.methods['mintBase(address,string)'](anyone, "base7", {from:owner});
            let newTokenId7 = 7;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId7), "ERC721Creator: No extension");

            await creator.methods['mintBase(address)'](anyone, {from:owner});
            let newTokenId8 = 8;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId8), "ERC721Creator: No extension");

            await creator.methods['mintBase(address)'](anyone, {from:owner});
            let newTokenId9 = 9;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId9), "ERC721Creator: No extension");

            // Check URI's
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId3), 'http://extension2/'+newTokenId3);
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.tokenURI(newTokenId5), 'extension5');
            assert.equal(await creator.tokenURI(newTokenId6), 'http://base/'+newTokenId6);
            assert.equal(await creator.tokenURI(newTokenId7), 'base7');
            assert.equal(await creator.tokenURI(newTokenId8), 'http://base/'+newTokenId8);
            assert.equal(await creator.tokenURI(newTokenId9), 'http://base/'+newTokenId9);

            // Set specific token uris and token prefixes
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256,string)'](creator.address, newTokenId1, 'bad', {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256[],string[])'](creator.address, [newTokenId1], ['bad'], {from:anyone}), "AdminControl: Must be owner or admin");
            await extension1.methods['setTokenURI(address,uint256,string)'](creator.address, newTokenId1, 'set1');
            await extension1.methods['setTokenURI(address,uint256[],string[])'](creator.address, [newTokenId2], ['set2']);
            await extension2.methods['setTokenURI(address,uint256,string)'](creator.address, newTokenId3, 'ext2/3');
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256,string)'](creator.address, newTokenId6, 'bad'), "ERC721Creator: Invalid token");
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256[],string[])'](creator.address, [newTokenId6], ['bad']), "ERC721Creator: Invalid token");
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256[],string[])'](creator.address, [], ['bad']), "ERC721Creator: Invalid input");
            await creator.methods['setTokenURI(uint256,string)'](newTokenId8, 'b8', {from:owner});
            await creator.methods['setTokenURI(uint256[],string[])']([newTokenId9], ['b9'], {from:owner});
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256,string)'](newTokenId1, 'bad', {from:owner}), "ERC721Creator: Invalid token");
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256[],string[])']([newTokenId1], ['bad'], {from:owner}), "ERC721Creator: Invalid token");
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256[],string[])']([], ['bad'], {from:owner}), "ERC721Creator: Invalid input");
            await creator.setTokenURIPrefix('http://prefix/', {from:owner});
            await extension1.setTokenURIPrefix('http://extension_prefix/');

            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension_prefix/set1');
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension_prefix/set2');
            assert.equal(await creator.tokenURI(newTokenId3), 'ext2/3');
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.tokenURI(newTokenId5), 'http://extension_prefix/extension5');
            assert.equal(await creator.tokenURI(newTokenId6), 'http://base/'+newTokenId6);
            assert.equal(await creator.tokenURI(newTokenId7), 'http://prefix/base7');

            // Removing extension should prevent further access
            await creator.unregisterExtension(extension1.address, {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            await truffleAssert.reverts(extension1.testMint(anyone), "ERC721Creator: Must be registered extension");

            // URI's should still be ok, tokens should still exist
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension_prefix/set1');
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension_prefix/set2');
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.tokenURI(newTokenId5), 'http://extension_prefix/extension5');

            // Burning
            await creator.burn(newTokenId1, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");

            // Check burn callback
            assert.equal(await extension1.burntTokens(), 1);
            assert.deepEqual((await extension1.burntTokens()).slice(-1)[0], web3.utils.toBN(newTokenId1));

            await creator.burn(newTokenId5, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");
        });

        it('creator batch mint test', async function () {
            await creator.setBaseTokenURI("http://base/", {from:owner});
            const extension = await MockERC721CreatorExtension.new(creator.address);
            await creator.registerExtension(extension.address, 'http://extension/', {from:owner});

            // Test minting
            await extension.methods['testMintBatch(address,uint16)'](anyone, 2);
            let newTokenId1 = 1;
            let newTokenId2 = 2;
            assert.equal(await creator.tokenExtension(newTokenId1), extension.address);
            assert.equal(await creator.tokenExtension(newTokenId2), extension.address);

            await extension.methods['testMintBatch(address,string[])'](another, ["t3", "t4"]);
            let newTokenId3 = 3;
            let newTokenId4 = 4;
            assert.equal(await creator.tokenExtension(newTokenId3), extension.address);
            assert.equal(await creator.tokenExtension(newTokenId4), extension.address);

            await creator.methods['mintBaseBatch(address,uint16)'](anyone, 2, {from:owner});
            let newTokenId5 = 5;
            let newTokenId6 = 6;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId5), "ERC721Creator: No extension");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId6), "ERC721Creator: No extension");

            await creator.methods['mintBaseBatch(address,string[])'](anyone, ["base7","base8"], {from:owner});
            let newTokenId7 = 7;
            let newTokenId8 = 8;

            // Check URI's
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId3), 't3');
            assert.equal(await creator.tokenURI(newTokenId4), 't4');
            assert.equal(await creator.tokenURI(newTokenId5), 'http://base/'+newTokenId5);
            assert.equal(await creator.tokenURI(newTokenId6), 'http://base/'+newTokenId6);
            assert.equal(await creator.tokenURI(newTokenId7), 'base7');
            assert.equal(await creator.tokenURI(newTokenId8), 'base8');
        });

        it('creator permissions functionality test', async function () {
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

    describe('ERC721CreatorEnumerable', function() {
        var creator;

        beforeEach(async function () {
            creator = await ERC721CreatorEnumerable.new(name, symbol, {from:owner});
        });

        it('creator enumerable blacklist extension test', async function() {
            await truffleAssert.reverts(creator.blacklistExtension(creator.address, {from:owner}), "RC721Creator: Cannot blacklist yourself");
            await creator.blacklistExtension(anyone, {from:owner});
            await truffleAssert.reverts(creator.totalSupplyExtension(anyone), "ERC721Creator: Extension blacklisted");
            await truffleAssert.reverts(creator.tokenByIndexExtension(anyone, 1), "ERC721Creator: Extension blacklisted");
            await truffleAssert.reverts(creator.balanceOfExtension(anyone, another), "ERC721Creator: Extension blacklisted");
            await truffleAssert.reverts(creator.tokenOfOwnerByIndexExtension(anyone, another, 1), "ERC721Creator: Extension blacklisted");

            const extension1 = await MockERC721CreatorExtension.new(creator.address);
            await creator.blacklistExtension(extension1.address, {from:owner});
            await truffleAssert.reverts(creator.registerExtension(extension1.address, 'http://extension1', {from:owner}), "ERC721Creator: Extension blacklisted");

            const extension2 = await MockERC721CreatorExtension.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:owner});
            await extension2.testMint(anyone);
            let newTokenId = (await extension2.mintedTokens()).slice(-1)[0];
            await creator.tokenURI(newTokenId);
            await creator.tokenExtension(newTokenId);
            await creator.blacklistExtension(extension2.address, {from:owner});
            await truffleAssert.reverts(creator.tokenURI(newTokenId), "ERC721Creator: Extension blacklisted");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId), "ERC721Creator: Extension blacklisted");
            
        });

        it('creator enumerable access test', async function () {
            await truffleAssert.reverts(creator.tokenByIndexExtension(anyone, 1), "ERC721Creator: Index out of bounds");
            await truffleAssert.reverts(creator.tokenOfOwnerByIndexExtension(anyone, anyone, 1), "ERC721Creator: Index out of bounds");
        });

        it('creator enumerable functionality test', async function () {
            assert.equal((await creator.getExtensions()).length, 0);

            await creator.setBaseTokenURI("http://base/", {from:owner});

            const extension1 = await MockERC721CreatorExtension.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 0);
            await truffleAssert.reverts(extension1.onBurn(anyone, 1), "ERC721CreatorExtensionBurnable: Can only be called by token creator");

            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            
            const extension2 = await MockERC721CreatorExtension.new(creator.address);
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

            await creator.mintBase(anyone, {from:owner});
            assert.equal(await creator.totalSupply(), 5);
            assert.equal(await creator.totalSupplyBase(), 1);
            assert.equal(await creator.balanceOfBase(anyone), 1);
            let newTokenId5 = await creator.tokenByIndexBase(0);
            assert.deepEqual(newTokenId5, await creator.tokenOfOwnerByIndexBase(anyone, 0));
            await truffleAssert.reverts(creator.tokenExtension(newTokenId5), "ERC721Creator: No extension");

            // Check URI's
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId3), 'http://extension2/'+newTokenId3);
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.tokenURI(newTokenId5), 'http://base/'+newTokenId5);

            // Removing extension should prevent further access
            await creator.unregisterExtension(extension1.address, {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            await truffleAssert.reverts(extension1.testMint(anyone), "ERC721Creator: Must be registered extension");

            // URI's should still be ok, tokens should still exist
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.totalSupply(), 5);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 3);

            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 0), newTokenId1);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 1), newTokenId2);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 2), newTokenId4);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 0), newTokenId1);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 1), newTokenId4);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, another, 0), newTokenId2);

            // Burning
            await creator.burn(newTokenId1, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");
            assert.equal(await creator.totalSupply(), 4);
            assert.equal(await creator.totalSupplyExtension(extension1.address), 2);
            assert.equal(await creator.balanceOfExtension(extension1.address, owner), 0);
            assert.equal(await creator.balanceOfExtension(extension1.address, anyone), 1);
            assert.equal(await creator.balanceOfExtension(extension2.address, anyone), 1);
            assert.equal(await creator.balanceOfExtension(extension1.address, another), 1);
            // Index shift after burn
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 0), newTokenId4);
            assert.deepEqual(await creator.tokenByIndexExtension(extension1.address, 1), newTokenId2);
            assert.deepEqual(await creator.tokenOfOwnerByIndexExtension(extension1.address, anyone, 0), newTokenId4);
            // Check burn callback
            assert.equal(await extension1.burntTokens(), 1);
            assert.deepEqual((await extension1.burntTokens()).slice(-1)[0], newTokenId1);

            await creator.burn(newTokenId5, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");
            assert.equal(await creator.totalSupply(), 3);
            assert.equal(await creator.totalSupplyBase(), 0);
            assert.equal(await creator.balanceOfBase(owner), 0);
        });

        it('creator enumerable permissions functionality test', async function () {
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