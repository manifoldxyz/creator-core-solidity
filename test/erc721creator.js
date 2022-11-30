const truffleAssert = require('truffle-assertions');

const ERC721Creator = artifacts.require("ERC721Creator");
const ERC721CreatorEnumerable = artifacts.require("ERC721CreatorEnumerable");
const MockERC721CreatorExtensionBurnable = artifacts.require("MockERC721CreatorExtensionBurnable");
const MockERC721CreatorExtensionOverride = artifacts.require("MockERC721CreatorExtensionOverride");
const MockERC721CreatorMintPermissions = artifacts.require("MockERC721CreatorMintPermissions");
const MockContract = artifacts.require("MockContract");
const toBN = web3.utils.toBN;

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

        it('supportsInterface test', async function () {
            // ICreatorCoreV1
            assert.equal(true, await creator.supportsInterface('0x28f10a21'));
            // ICreatorCoreV2
            assert.equal(true, await creator.supportsInterface('0x5365e65c'));
            // IERC721CreatorCore
            assert.equal(true, await creator.supportsInterface('0x9088c207'));
            // Creator Core Royalites
            assert.equal(true, await creator.supportsInterface('0xbb3bafd6'));
            // EIP-2981 Royalites
            assert.equal(true, await creator.supportsInterface('0x2a55205a'));
            // RaribleV1 Royalites
            assert.equal(true, await creator.supportsInterface('0xb7799584'));
            // Foundation Royalites
            assert.equal(true, await creator.supportsInterface('0xd5a06d4c'));
        });

        it('creator should support transfer approvals', async () => {
            const baseApprover = await MockERC721CreatorExtensionOverride.new(creator.address, {from:owner});
            const extApprover = await MockERC721CreatorExtensionOverride.new(creator.address, {from:owner});
            const extAnon = await MockERC721CreatorExtensionBurnable.new(creator.address, {from:owner});

            await baseApprover.setApproveEnabled(true);
            await extApprover.setApproveEnabled(true);
            await creator.registerExtension(extApprover.address, "", {from:owner});
            await creator.registerExtension(extAnon.address, "", {from:owner});

            // mint 3 tokens, one base, one on approval extension, one on anon extension
            await creator.mintBase(owner, {from:owner});         
            await extApprover.testMint(owner, {from:owner});
            await extAnon.testMint(owner, {from:owner});

            // no approvers set; all should work
            await creator.transferFrom(owner, another, 1, {from:owner});
            await creator.transferFrom(owner, another, 2, {from:owner});
            await creator.transferFrom(owner, another, 3, {from:owner});

            // set base approver but don't block transfers
            await truffleAssert.reverts(creator.setApproveTransfer(baseApprover.address, {from:another}), 'AdminControl: Must be owner or admin');
            await creator.setApproveTransfer(baseApprover.address, {from:owner});
            assert.equal(await creator.getApproveTransfer(), baseApprover.address);
            await creator.safeTransferFrom(another, owner, 1, {from:another});
            await creator.safeTransferFrom(another, owner, 2, {from:another});
            await creator.safeTransferFrom(another, owner, 3, {from:another});

            // block extension only
            await extApprover.setApproveEnabled(false);
            await creator.safeTransferFrom(owner, another, 1, {from:owner});
            await truffleAssert.reverts(creator.safeTransferFrom(owner, another, 2, {from:owner}), 'Extension approval failure');
            await creator.safeTransferFrom(owner, another, 3, {from:owner});

            // block on base; approval extension override
            await baseApprover.setApproveEnabled(false);
            await extApprover.setApproveEnabled(true);
            await truffleAssert.reverts(creator.transferFrom(another, owner, 1, {from:another}), 'Extension approval failure');
            await creator.transferFrom(owner, another, 2, {from:owner});
            await truffleAssert.reverts(creator.transferFrom(another, owner, 3, {from:another}), 'Extension approval failure');

            // unregister approval extension
            await extApprover.setApproveEnabled(false);
            await creator.unregisterExtension(extApprover.address, {from:owner});
            await truffleAssert.reverts(creator.transferFrom(another, owner, 1, {from:another}), 'Extension approval failure');
            await truffleAssert.reverts(creator.transferFrom(another, owner, 2, {from:another}), 'Extension approval failure');
            await truffleAssert.reverts(creator.transferFrom(another, owner, 3, {from:another}), 'Extension approval failure');
            
            // disable base approver, approval extension override should still block
            await creator.setApproveTransfer("0x0000000000000000000000000000000000000000", {from:owner});
            assert.equal(await creator.getApproveTransfer(), "0x0000000000000000000000000000000000000000");
            await creator.transferFrom(another, owner, 1, {from:another});
            await truffleAssert.reverts(creator.transferFrom(another, owner, 2, {from:another}), 'Extension approval failure');
            await creator.transferFrom(another, owner, 3, {from:another});
        });

        it('creator extension override test', async function () {
            await truffleAssert.reverts(creator.registerExtension(creator.address, '', {from:owner}), "Invalid")
            var extension = await MockERC721CreatorExtensionOverride.new(creator.address, {from:owner});
            await creator.registerExtension(extension.address, 'http://extension/', {from:owner});
            // Test legacy interface support
            assert.equal(true, await extension.supportsInterface('0x7005caad'));
            assert.equal(true, await extension.supportsInterface('0x45ffcdad'));

            // Test approve transfer overrides
            await truffleAssert.reverts(extension.testMint(anyone), "Extension approval failure");
            await extension.setApproveTransfer(creator.address, false, {from:owner});
            await extension.testMint(anyone);
            var tokenId = 1;
            await creator.transferFrom(anyone, another, tokenId, {from:anyone});
            await truffleAssert.reverts(extension.setApproveTransfer(creator.address, true, {from:anyone}), "AdminControl: Must be owner or admin");
            await extension.setApproveTransfer(creator.address, true, {from:owner});
            await truffleAssert.reverts(creator.transferFrom(another, anyone, tokenId, {from:another}), "Extension approval failure");
            await extension.setApproveEnabled(true);
            await creator.transferFrom(another, anyone, tokenId, {from:another});

            // test tokenuri overrides
            await extension.setTokenURI('override');
            assert.equal(await creator.tokenURI(tokenId), 'override');
        });

        it('creator should respect royalty override order', async function () {
            let extension = await MockERC721CreatorExtensionOverride.new(creator.address, { from: owner });
            await creator.registerExtension(extension.address, 'http://extension/', { from: owner });
            await extension.setApproveTransfer(creator.address, false, { from: owner });

            // royalty priority (highest to lowest)
            // 1. token
            // 2. extension override 
            // 3. extension default 
            // 4. creator default
            await extension.testMint(anyone);
            await creator.mintBase(anyone, { from: owner });

            assert.deepEqual([[], []], Object.values(await creator.getRoyalties(1)));
            assert.deepEqual([[], []], Object.values(await creator.getRoyalties(2)));

            await creator.methods['setRoyalties(address[],uint256[])']([anyone], [1], {from: owner});
            assert.deepEqual([[anyone], [toBN(1)]], Object.values(await creator.getRoyalties(1)));
            assert.deepEqual([[anyone], [toBN(1)]], Object.values(await creator.getRoyalties(2)));

            await creator.setRoyaltiesExtension(extension.address, [another], [10], {from:owner});
            assert.deepEqual([[another], [toBN(10)]], Object.values(await creator.getRoyalties(1)));
            assert.deepEqual([[anyone], [toBN(1)]], Object.values(await creator.getRoyalties(2)));

            await extension.setRoyaltyOverrides(1, [owner], [100], { from: owner });
            assert.deepEqual([[owner], [toBN(100)]], Object.values(await creator.getRoyalties(1)));
            assert.deepEqual([[anyone], [toBN(1)]], Object.values(await creator.getRoyalties(2)));

            await creator.methods['setRoyalties(uint256,address[],uint256[])'](1, [newOwner], [200], { from: owner });
            assert.deepEqual([[newOwner], [toBN(200)]], Object.values(await creator.getRoyalties(1)));
            assert.deepEqual([[anyone], [toBN(1)]], Object.values(await creator.getRoyalties(2)));
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
            await truffleAssert.reverts(creator.methods['mintBase(address)'](anyone, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintBase(address,string)'](anyone, "", {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintBaseBatch(address,uint16)'](anyone, 1, {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintBaseBatch(address,string[])'](anyone, [""], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['mintExtension(address)'](anyone, {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.methods['mintExtension(address,string)'](anyone, "", {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.methods['mintExtensionBatch(address,uint16)'](anyone, 1, {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.methods['mintExtensionBatch(address,string[])'](anyone, [""], {from:anyone}), "Must be registered extension");
            await truffleAssert.reverts(creator.methods['setRoyalties(address[],uint256[])']([anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['setRoyalties(uint256,address[],uint256[])'](1, [anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.methods['setRoyaltiesExtension(address,address[],uint256[])'](anyone, [anyone], [100], {from:anyone}), "AdminControl: Must be owner or admin");
            await truffleAssert.reverts(creator.setApproveTransferExtension(true, {from:anyone}), "Must be registered extension");
        });
        
        it('creator blacklist extension test', async function() {
            await truffleAssert.reverts(creator.blacklistExtension(creator.address, {from:owner}), "Cannot blacklist yourself");
            await creator.blacklistExtension(anyone, {from:owner});

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

        it('creator gas test', async function () {
            // Prime data with one mint first
            var tx = await creator.methods['mintBase(address)'](anyone, {from:owner});
        
            tx = await creator.methods['mintBase(address,string)'](anyone, "https://arweave.net/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", {from:owner});
            console.log(`mintBase with 'https://arweave.net/' cost: ${tx.receipt.gasUsed}`);

            tx = await creator.methods['mintBase(address,string)'](anyone, "ar://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX", {from:owner});
            console.log(`mintBase with 'ar://' cost: ${tx.receipt.gasUsed}`);
        });
      
        it('creator functionality test', async function () {
            assert.equal((await creator.getExtensions()).length, 0);

            await creator.setBaseTokenURI("http://base/", {from:owner});

            const extension1 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            assert.equal((await creator.getExtensions()).length, 0);
            await truffleAssert.reverts(extension1.onBurn(anyone, 1), "Can only be called by token creator");
            // Test legacy interface support
            assert.equal(true, await extension1.supportsInterface('0x7005caad'));
            assert.equal(true, await extension1.supportsInterface('0xf3f4e68b'));

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
            await truffleAssert.reverts(creator.tokenExtension(newTokenId6), "No extension for token");

            await creator.methods['mintBase(address,string)'](anyone, "base7", {from:owner});
            let newTokenId7 = 7;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId7), "No extension for token");

            await creator.methods['mintBase(address)'](anyone, {from:owner});
            let newTokenId8 = 8;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId8), "No extension for token");

            await creator.methods['mintBase(address)'](anyone, {from:owner});
            let newTokenId9 = 9;
            await truffleAssert.reverts(creator.tokenExtension(newTokenId9), "No extension for token");

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
            await truffleAssert.reverts(extension1.testMint(anyone), "Must be registered extension");

            // URI's should still be ok, tokens should still exist
            assert.equal(await creator.tokenURI(newTokenId1), 'http://extension_prefix/set1');
            assert.equal(await creator.tokenURI(newTokenId2), 'http://extension_prefix/set2');
            assert.equal(await creator.tokenURI(newTokenId4), 'http://extension1/'+newTokenId4);
            assert.equal(await creator.tokenURI(newTokenId5), 'http://extension_prefix/extension5');

            // Burning
            await truffleAssert.reverts(creator.burn(newTokenId1, {from:another}), "Caller is not owner nor approved");
            await creator.burn(newTokenId1, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");

            // Check burn callback
            assert.equal(await extension1.burntTokens(), 1);
            assert.deepEqual((await extension1.burntTokens()).slice(-1)[0], toBN(newTokenId1));

            await creator.burn(newTokenId5, {from:anyone});
            await truffleAssert.reverts(creator.tokenURI(newTokenId1), "Nonexistent token");
        });

        it('creator batch mint test', async function () {
            await creator.setBaseTokenURI("http://base/", {from:owner});
            const extension = await MockERC721CreatorExtensionBurnable.new(creator.address);
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
            await truffleAssert.reverts(creator.tokenExtension(newTokenId5), "No extension for token");
            await truffleAssert.reverts(creator.tokenExtension(newTokenId6), "No extension for token");

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
            const extension1 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension1.address, 'http://extension1/', {from:owner});
            
            const extension2 = await MockERC721CreatorExtensionBurnable.new(creator.address);
            await creator.registerExtension(extension2.address, 'http://extension2/', {from:owner});

            await truffleAssert.reverts(MockERC721CreatorMintPermissions.new(anyone), "Must implement IERC721CreatorCore");
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

        it('creator royalites update test', async function () {
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
            results = await creator.getFees(tokenId1);
            assert.equal(results[0].length, 2);
            assert.equal(results[1].length, 2);
            results = await creator.getFeeRecipients(tokenId1);
            assert.equal(results.length, 2);
            results = await creator.getFeeBps(tokenId1);
            assert.equal(results.length, 2);
            await truffleAssert.reverts(creator.royaltyInfo(tokenId1, 10000), "More than 1 royalty receiver");

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
            results = await creator.royaltyInfo(tokenId2, 10000);
            assert.deepEqual(toBN(10000*123/10000), results[1]);

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
