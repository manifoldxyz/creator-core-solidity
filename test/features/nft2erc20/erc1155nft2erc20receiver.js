const truffleAssert = require('truffle-assertions');

const NFT2ERC20 = artifacts.require("NFT2ERC20");
const ERC1155NFT2ERC20Receiver = artifacts.require("ERC1155NFT2ERC20Receiver");
const MockERC1155 = artifacts.require("MockERC1155");
const MockNFT2ERC20RateEngine = artifacts.require("MockNFT2ERC20RateEngine");

contract('ERC1155NFT2ERC20Receiver', function ([creator, ...accounts]) {
    const name = 'Token';
    const symbol = 'NFT';
    const minter = creator;
    const [
           owner,
           newOwner,
           another,
           anyone,
           ] = accounts;

    describe('ERC1155NFT2ERC20Receiver', function() {
        var token;
        var mockRateEngine;
        var receiver;
        var mock1155;

        beforeEach(async function () {
            token = await NFT2ERC20.new(name, symbol, {from:owner});
            mock1155 = await MockERC1155.new('1155uri', {from:owner});
            mockRateEngine = await MockNFT2ERC20RateEngine.new();
            token.setRateEngine(mockRateEngine.address, {from:owner});
            receiver = await ERC1155NFT2ERC20Receiver.new(token.address);
        });

        it('receiver test', async function () {
            await mock1155.testMint(another, 1155, 10, "0x0");
            assert.equal(await mock1155.balanceOf(another, 1155), 10);
            await token.setTransferFunction('erc1155', '0xf242432a', {from:owner});

            await mock1155.safeTransferFrom(another, receiver.address, 1155, 2, '0x0', {from:another});
            assert.equal(await mock1155.balanceOf(another, 1155), 8);
            assert.equal(await mock1155.balanceOf(receiver.address, 1155), 0);
            assert.equal(await token.balanceOf(another), 10);

            await mock1155.safeBatchTransferFrom(another, receiver.address, [1155], [2], '0x0', {from:another});
            assert.equal(await mock1155.balanceOf(another, 1155), 6);
            assert.equal(await mock1155.balanceOf(receiver.address, 1155), 0);
            assert.equal(await token.balanceOf(another), 20);

        });
    });

});