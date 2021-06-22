const truffleAssert = require('truffle-assertions');

const ERC1155Creator = artifacts.require("ERC1155Creator");
const MockERC1155CreatorExtensionBurnable = artifacts.require("MockERC1155CreatorExtensionBurnable");
const MockERC1155CreatorExtensionOverride = artifacts.require("MockERC1155CreatorExtensionOverride");
const MockERC1155CreatorMintPermissions = artifacts.require("MockERC1155CreatorMintPermissions");
const MockERC1155 = artifacts.require("MockERC1155");
const MockContract = artifacts.require("MockContract");

contract('ERC1155Creator', function ([minter_account, ...accounts]) {
    const minter = minter_account;
    const [
           owner,
           newOwner,
           another,
           anyone,
           ] = accounts;

    it('creator gas', async function () {
        const creatorGasEstimate = await ERC1155Creator.new.estimateGas({from:owner});
        console.log("ERC1155Creator gas estimate: %s", creatorGasEstimate);
    });

    describe('ERC1155Creator', function() {
        var creator;

        beforeEach(async function () {
            creator = await ERC1155Creator.new({from:owner});
        });

        it('supportsInterface test', async function () {
            // ICreatorCore
            assert.equal(true, await creator.supportsInterface('0x28f10a21'));
            // IERC1155CreatorCore
            assert.equal(true, await creator.supportsInterface('0x7d248440'));
            // Creator Core Royalites
            assert.equal(true, await creator.supportsInterface('0xbb3bafd6'));
            // EIP-2981 Royalites
            assert.equal(true, await creator.supportsInterface('0x2a55205a'));
            // RaribleV1 Royalites
            assert.equal(true, await creator.supportsInterface('0xb7799584'));
            // Foundation Royalites
            assert.equal(true, await creator.supportsInterface('0xd5a06d4c'));
        });

        it('creator extension override test', async function () {
            await truffleAssert.reverts(creator.registerExtension(creator.address, '', {from:owner}), "Creator: Invalid")
            var extension = await MockERC1155CreatorExtensionOverride.new(creator.address, {from:owner});
            await creator.registerExtension(extension.address, 'http://extension/', {from:owner});

            await extension.testMintNew([anyone], [100], [""]);
            var tokenId = 1;
            await creator.safeTransferFrom(anyone, another, tokenId, 100, "0x0", {from:anyone});
            await truffleAssert.reverts(extension.setApproveTransfer(creator.address, true, {from:anyone}), "AdminControl: Must be owner or admin");
            await extension.setApproveTransfer(creator.address, true, {from:owner});
            await truffleAssert.reverts(creator.safeTransferFrom(another, anyone, tokenId, 100, "0x0", {from:another}), "Extension approval failure");
            await extension.setApproveEnabled(true);
            await creator.safeTransferFrom(another, anyone, tokenId, 100, "0x0", {from:another});

            await extension.setTokenURI('override');
            assert.equal(await creator.uri(tokenId), 'override');
        });

        it('creator permission test', async function () {
            await truffleAssert.reverts(creator.registerExtension(anyone, 'http://extension', {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.registerExtension(anyone, 'http://extension', true), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.unregisterExtension(anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.blacklistExtension(anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setBaseTokenURIExtension('http://extension', {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.setBaseTokenURIExtension('http://extension', true), "Must be registered extension");
            await truffleAssert.reverts(creator.setTokenURIPrefixExtension('http://extension', {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.methods['setTokenURIExtension(uint256,string)'](1, 'http://extension', {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.methods['setTokenURIExtension(uint256[],string[])']([1], ['http://extension'], {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.setBaseTokenURI('http://base', {from:anyone}),"AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setTokenURIPrefix('http://base', {from:anyone}),"AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256,string)'](1, 'http://base', {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256[],string[])']([1], ['http://base'], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setMintPermissions(anyone, anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [1], [""], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintExtensionNew(address[],uint256[],string[])']([anyone], [1], [""], {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone], [1], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintExtensionExisting(address[],uint256[],uint256[])']([anyone], [1], [100], {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.methods['setRoyalties(address[],uint256[])']([anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['setRoyalties(uint256,address[],uint256[])'](1, [anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['setRoyaltiesExtension(address,address[],uint256[])'](anyone, [anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setApproveTransferExtension(true, {from:anyone}), "Must be registered extension");
        });
        
        it('creator blacklist extension test', async function() {
            await truffleAssert.reverts(creator.blacklistExtension(creator.address, {from:owner}), "Cannot blacklist yourself");
            await creator.blacklistExtension(anyone, {from:owner});

            const extension1 = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            await creator.blacklistExtension(extension1.address, {from:owner});
            await truffleAssert.reverts(creator.registerExtension(extension1.address, 'http://extension1', {from:owner}), "Extension blacklisted");

            const extension2 = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:owner});
            await extension2.testMintNew([anyone], [100], [""]);
            let newTokenId = (await extension2.mintedTokens()).slice(-1)[0];
            await creator.uri(newTokenId);
            await creator.tokenExtension(newTokenId);
            await creator.blacklistExtension(extension2.address, {from:owner});
            await truffleAssert.reverts(creator.uri(newTokenId), "Extension blacklisted");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId), "Extension blacklisted");
        });

        it('creator functionality test', async function () {
            assert.equal((await creator.getExtensions()).length, 0);

            await creator.setBaseTokenURI("http://base/", {from:owner});

            const extension1 = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 0);
            await truffleAssert.reverts(extension1.onBurn(anyone, [1], [100]), "Can only be called by token creator");
 
            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            
            const extension2 = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 1);

            // Admins can register extensions
            await creator.approveAdmin(another, {from:owner});
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:another});
            assert.equal((await creator.getExtensions()).length, 2);

            // Minting cost
            const mintBase = await creator.mintBaseNew.estimateGas([anyone], [100], [""], {from:owner});
            console.log("No Extension mint gas estimate: %s", mintBase);
            const mintGasEstimate = await extension1.testMintNew.estimateGas([anyone], [100], [""]);
            console.log("Extension mint gas estimate: %s", mintGasEstimate);

            // Test minting
            await extension1.testMintNew([anyone], [100], [""]);
            let newTokenId1 = 1;
            assert.equal(await creator.tokenExtension(newTokenId1), extension1.address);

            await extension1.testMintNew([another], [200], [""]);
            let newTokenId2 = 2;

            await extension2.testMintNew([anyone], [300], [""]);
            let newTokenId3 = 3;

            await extension1.testMintNew([anyone], [400], [""]);
            let newTokenId4 = 4;

            await extension1.testMintNew([anyone], [500], ["extension5"]);
            let newTokenId5 = 5;

            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [600], [""], {from:owner});
            let newTokenId6 = 6;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId6), "No extension for token");

            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [700], ["base7"], {from:owner});
            let newTokenId7 = 7;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId7), "No extension for token");

            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [800], [""], {from:owner});
            let newTokenId8 = 8;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId8), "No extension for token");

            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [900], [""], {from:owner});
            let newTokenId9 = 9;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId9), "No extension for token");

            // Check URI's
            assert.equal(await creator.uri(newTokenId1), 'http://extension1/'+newTokenId1);
            assert.equal(await creator.uri(newTokenId2), 'http://extension1/'+newTokenId2);
            assert.equal(await creator.uri(newTokenId3), 'http://extension2/'+newTokenId3);
            assert.equal(await creator.uri(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.uri(newTokenId5), 'extension5');
            assert.equal(await creator.uri(newTokenId6), 'http://base/'+newTokenId6);
            assert.equal(await creator.uri(newTokenId7), 'base7');
            assert.equal(await creator.uri(newTokenId8), 'http://base/'+newTokenId8);
            assert.equal(await creator.uri(newTokenId9), 'http://base/'+newTokenId9);

            // Set specific token uris and token prefixes
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256,string)'](creator.address, newTokenId1, 'bad', {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256[],string[])'](creator.address, [newTokenId1], ['bad'], {from:anyone}), "AdminControl: Must be owner or admin");
            await extension1.methods['setTokenURI(address,uint256,string)'](creator.address, newTokenId1, 'set1');
            await extension1.methods['setTokenURI(address,uint256[],string[])'](creator.address, [newTokenId2], ['set2']);
            await extension2.methods['setTokenURI(address,uint256,string)'](creator.address, newTokenId3, 'ext2/3');
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256,string)'](creator.address, newTokenId6, 'bad'), "Invalid token");
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256[],string[])'](creator.address, [newTokenId6], ['bad']), "Invalid token");
            await truffleAssert.reverts(extension1.methods['setTokenURI(address,uint256[],string[])'](creator.address, [], ['bad']), "Invalid input");
            await creator.methods['setTokenURI(uint256,string)'](newTokenId8, 'b8', {from:owner});
            await creator.methods['setTokenURI(uint256[],string[])']([newTokenId9], ['b9'], {from:owner});
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256,string)'](newTokenId1, 'bad', {from:owner}), "Invalid token");
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256[],string[])']([newTokenId1], ['bad'], {from:owner}), "Invalid token");
            await truffleAssert.reverts(creator.methods['setTokenURI(uint256[],string[])']([], ['bad'], {from:owner}), "Invalid input");
            await creator.setTokenURIPrefix('http://prefix/', {from:owner});
            await extension1.setTokenURIPrefix(creator.address, 'http://extension_prefix/');

            assert.equal(await creator.uri(newTokenId1), 'http://extension_prefix/set1');
            assert.equal(await creator.uri(newTokenId2), 'http://extension_prefix/set2');
            assert.equal(await creator.uri(newTokenId3), 'ext2/3');
            assert.equal(await creator.uri(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.uri(newTokenId5), 'http://extension_prefix/extension5');
            assert.equal(await creator.uri(newTokenId6), 'http://base/'+newTokenId6);
            assert.equal(await creator.uri(newTokenId7), 'http://prefix/base7');

            // Removing extension should prevent further access
            await creator.unregisterExtension(extension1.address, {from:owner});
            assert.equal((await creator.getExtensions()).length, 1);
            await truffleAssert.reverts(extension1.testMintNew([anyone],[100],[""]), "Must be registered extension");

            // URI's should still be ok, tokens should still exist
            assert.equal(await creator.uri(newTokenId1), 'http://extension_prefix/set1');
            assert.equal(await creator.uri(newTokenId2), 'http://extension_prefix/set2');
            assert.equal(await creator.uri(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.uri(newTokenId5), 'http://extension_prefix/extension5');

            // Burning
            await truffleAssert.reverts(creator.burn(anyone, [newTokenId1], [100], {from:another}), "Caller is not owner nor approved");
            await truffleAssert.reverts(creator.burn(anyone, [newTokenId1], [1,100], {from:anyone}), "Invalid input");
            await creator.burn(anyone, [newTokenId1], [50], {from:anyone});
            await creator.burn(anyone, [newTokenId1], [25], {from:anyone});
            await truffleAssert.reverts(creator.burn(anyone, [newTokenId1], [100], {from:anyone}), "ERC1155: burn amount exceeds balance");
            await truffleAssert.reverts(creator.burn(anyone, [newTokenId1], [100], {from:anyone}), "ERC1155: burn amount exceeds balance");
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId1), web3.utils.toBN(25));

            // Check burn callback
            assert.deepEqual(await extension1.burntTokens(newTokenId1), web3.utils.toBN(75));

        });

        it('creator batch mint test', async function () {
            await creator.setBaseTokenURI("http://base/", {from:owner});
            const extension = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension.address, 'http://extension/', {from:owner});

            // Test minting
            await extension.methods['testMintNew(address[],uint256[],string[])']([anyone], [100,200,300,400], ["","","t3","t4"]);
            await extension.methods['testMintNew(address[],uint256[],string[])']([anyone,another], [500], []);
            await extension.methods['testMintNew(address[],uint256[],string[])']([anyone,another], [600,601], ["t6"]);
            await truffleAssert.reverts(extension.methods['testMintNew(address[],uint256[],string[])']([anyone,another], [600], ["",""]), "Invalid input");
            await truffleAssert.reverts(extension.methods['testMintNew(address[],uint256[],string[])']([anyone,another], [600,700,800], []), "Invalid input");
            let newTokenId1 = 1;
            let newTokenId2 = 2;
            let newTokenId3 = 3;
            let newTokenId4 = 4;
            let newTokenId5 = 5;
            let newTokenId6 = 6;
            assert.equal(await creator.tokenExtension(newTokenId1), extension.address);
            assert.equal(await creator.tokenExtension(newTokenId2), extension.address);
            assert.equal(await creator.tokenExtension(newTokenId3), extension.address);
            assert.equal(await creator.tokenExtension(newTokenId4), extension.address);
            assert.equal(await creator.tokenExtension(newTokenId5), extension.address);
            assert.equal(await creator.tokenExtension(newTokenId6), extension.address);

            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [700,800,900,1000], ["","","base9","base10"], {from:owner});
            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone,another], [1100], [], {from:owner});
            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone,another], [1200,1201], ["base12"], {from:owner});
            await truffleAssert.reverts(creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone,another], [1100], ["",""], {from:owner}), "Invalid input");
            await truffleAssert.reverts(creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone,another], [1100,1200,1300], [], {from:owner}), "Invalid input");
            let newTokenId7 = 7;
            let newTokenId8 = 8;
            let newTokenId9 = 9;
            let newTokenId10 = 10;
            let newTokenId11 = 11;
            let newTokenId12 = 12;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId7), "No extension for token");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId8), "No extension for token");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId9), "No extension for token");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId10), "No extension for token");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId11), "No extension for token");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId12), "No extension for token");

            // Check balances
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId1), web3.utils.toBN(100));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId2), web3.utils.toBN(200));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId3), web3.utils.toBN(300));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId4), web3.utils.toBN(400));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId5), web3.utils.toBN(500));
            assert.deepEqual(await creator.balanceOf(another, newTokenId5), web3.utils.toBN(500));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId6), web3.utils.toBN(600));
            assert.deepEqual(await creator.balanceOf(another, newTokenId6), web3.utils.toBN(601));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId7), web3.utils.toBN(700));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId8), web3.utils.toBN(800));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId9), web3.utils.toBN(900));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId10), web3.utils.toBN(1000));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId11), web3.utils.toBN(1100));
            assert.deepEqual(await creator.balanceOf(another, newTokenId11), web3.utils.toBN(1100));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId12), web3.utils.toBN(1200));
            assert.deepEqual(await creator.balanceOf(another, newTokenId12), web3.utils.toBN(1201));

            // Check URI's
            assert.equal(await creator.uri(newTokenId1), 'http://extension/'+newTokenId1);
            assert.equal(await creator.uri(newTokenId2), 'http://extension/'+newTokenId2);
            assert.equal(await creator.uri(newTokenId3), 't3');
            assert.equal(await creator.uri(newTokenId4), 't4');
            assert.equal(await creator.uri(newTokenId5), 'http://extension/'+newTokenId5);
            assert.equal(await creator.uri(newTokenId6), 't6');
            assert.equal(await creator.uri(newTokenId7), 'http://base/'+newTokenId7);
            assert.equal(await creator.uri(newTokenId8), 'http://base/'+newTokenId8);
            assert.equal(await creator.uri(newTokenId9), 'base9');
            assert.equal(await creator.uri(newTokenId10), 'base10');
            assert.equal(await creator.uri(newTokenId11), 'http://base/'+newTokenId11);
            assert.equal(await creator.uri(newTokenId12), 'base12');
        });


        it('creator existing mint test', async function () {
            const extension1 = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension1.address, 'http://extension/', {from:owner});
            const extension2 = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension/', {from:owner});

            // Test minting
            await extension1.methods['testMintNew(address[],uint256[],string[])']([anyone], [100], [""]);
            await extension1.methods['testMintNew(address[],uint256[],string[])']([anyone], [200], [""]);
            let newTokenId1 = 1;
            let newTokenId2 = 2;
            await extension2.methods['testMintNew(address[],uint256[],string[])']([anyone], [300], [""]);
            await extension2.methods['testMintNew(address[],uint256[],string[])']([anyone], [400], [""]);
            let newTokenId3 = 3;
            let newTokenId4 = 4;
            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [500], [""], {from:owner});
            await creator.methods['mintBaseNew(address[],uint256[],string[])']([anyone], [600], [""], {from:owner});
            let newTokenId5 = 5;
            let newTokenId6 = 6;

            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId1],[1],{from:owner}), "A token was created by an extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId2],[1],{from:owner}), "A token was created by an extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId3],[1],{from:owner}), "A token was created by an extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId4],[1],{from:owner}), "A token was created by an extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId5,newTokenId1],[1,1],{from:owner}), "A token was created by an extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId5,newTokenId2],[1,1],{from:owner}), "A token was created by an extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId5,newTokenId3],[1,1],{from:owner}), "A token was created by an extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId5,newTokenId4],[1,1],{from:owner}), "A token was created by an extension");
            await truffleAssert.reverts(creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId5,newTokenId6],[1,1,3],{from:owner}), "Invalid input");

            await creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId5],[1],{from:owner});
            await creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone],[newTokenId5,newTokenId6],[1,10],{from:owner});
            await creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone,another],[newTokenId5],[3],{from:owner});
            await creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone,another],[newTokenId5],[1,2],{from:owner});
            await creator.methods['mintBaseExisting(address[],uint256[],uint256[])']([anyone,another],[newTokenId5,newTokenId6],[3,4],{from:owner});
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId5), web3.utils.toBN(509));
            assert.deepEqual(await creator.balanceOf(another, newTokenId5), web3.utils.toBN(5));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId6), web3.utils.toBN(610));
            assert.deepEqual(await creator.balanceOf(another, newTokenId6), web3.utils.toBN(4));

            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId3],[1]), "A token was not created by this extension");
            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId4],[1]), "A token was not created by this extension");
            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId5],[1]), "A token was not created by this extension");
            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId6],[1]), "A token was not created by this extension");
            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId1,newTokenId3],[1,10]), "A token was not created by this extension");
            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId1,newTokenId4],[1,10]), "A token was not created by this extension");
            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId1,newTokenId5],[1,10]), "A token was not created by this extension");
            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId1,newTokenId6],[1,10]), "A token was not created by this extension");
            await truffleAssert.reverts(extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId1,newTokenId2],[1,10,20]), "Invalid input");

            await extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId1],[1]);
            await extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone],[newTokenId1,newTokenId2],[1,10]);
            await extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone,another],[newTokenId1],[3],{from:owner});
            await extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone,another],[newTokenId1],[1,2],{from:owner});
            await extension1.methods['testMintExisting(address[],uint256[],uint256[])']([anyone,another],[newTokenId1,newTokenId2],[3,4],{from:owner});
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId1), web3.utils.toBN(109));
            assert.deepEqual(await creator.balanceOf(another, newTokenId1), web3.utils.toBN(5));
            assert.deepEqual(await creator.balanceOf(anyone, newTokenId2), web3.utils.toBN(210));
            assert.deepEqual(await creator.balanceOf(another, newTokenId2), web3.utils.toBN(4));

        });

        it('creator permissions functionality test', async function () {
            const extension1 = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            
            const extension2 = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:owner});

            await truffleAssert.reverts(MockERC1155CreatorMintPermissions.new(anyone), "Must implement IERC1155CreatorCore");
            const permissions = await MockERC1155CreatorMintPermissions.new(creator.address);
            await truffleAssert.reverts(permissions.approveMint(anyone, [anyone], [1], [100]), "Can only be called by token creator");
            
            await truffleAssert.reverts(creator.setMintPermissions(extension1.address, anyone, {from:owner}), "Invalid address");
            await creator.setMintPermissions(extension1.address, permissions.address, {from:owner});
            
            await extension1.testMintNew([anyone],[100],[""]);
            await extension2.testMintNew([anyone],[100],[""]);

            permissions.setApproveEnabled(false);
            await truffleAssert.reverts(extension1.testMintNew([anyone],[100],[""]), "MockERC1155CreatorMintPermissions: Disabled");
            await extension2.testMintNew([anyone],[100],[""]);

            await creator.setMintPermissions(extension1.address, '0x0000000000000000000000000000000000000000', {from:owner});
            await extension1.testMintNew([anyone],[100],[""]);
            await extension2.testMintNew([anyone],[100],[""]);
        });

        it('creator royalites update test', async function () {
            await creator.mintBaseNew([anyone], [100], [""], {from:owner});
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
            results = await creator.getFees(tokenId1);
            assert.equal(results[0].length, 2);
            assert.equal(results[1].length, 2);
            results = await creator.getFeeRecipients(tokenId1);
            assert.equal(results.length, 2);
            results = await creator.getFeeBps(tokenId1);
            assert.equal(results.length, 2);
            await truffleAssert.reverts(creator.royaltyInfo(tokenId1, 10000), "More than 1 royalty receiver");

            const extension = await MockERC1155CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension.address, 'http://extension/', {from:owner});
            await extension.testMintNew([anyone],[200],[""]);
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
            results = await creator.royaltyInfo(tokenId2, 10000);
            assert.deepEqual(web3.utils.toBN(10000*123/10000), results[1]);

            await creator.mintBaseNew([anyone], [300], [""], {from:owner});
            var tokenId3 = 3;
            await extension.testMintNew([anyone], [400], [""]);
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