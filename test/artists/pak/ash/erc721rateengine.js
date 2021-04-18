const truffleAssert = require('truffle-assertions');

const ERC721RateEngine = artifacts.require("ERC721RateEngine");

contract('ERC721RateEngine', function ([creator, ...accounts]) {
    const name = 'Token';
    const symbol = 'NFT';
    const minter = creator;
    const [
           owner,
           newOwner,
           another,
           anyone,
           ] = accounts;

    describe('ERC721RateEngine', function() {
        var engine;
        var nn;

        beforeEach(async function () {
            engine = await ERC721RateEngine.new();
        });

        it('permission test', async function () {
            var newEngine = await ERC721RateEngine.new({from:anyone});
            await truffleAssert.reverts(newEngine.updateRateClass([minter], [1]), "Must be owner or admin");
            await truffleAssert.reverts(newEngine.updateRateClass([minter], [1], [1]), "Must be owner or admin");
            await truffleAssert.reverts(newEngine.updateEnabled(true), "Must be owner or admin");
        });

        it('config test', async function () {
            await engine.updateRateClass([minter], [1]);
            await truffleAssert.reverts(engine.getRate(0, minter, [1], 'erc721'), "Disabled");
            await engine.updateEnabled(true);
            await truffleAssert.reverts(engine.getRate(0, minter, [], 'erc721'), "Invalid arguments");
            await truffleAssert.reverts(engine.getRate(0, minter, [1], 'erc1155'), "Only ERC721 currently supported");
            await truffleAssert.reverts(engine.getRate(0, anyone, [1], 'erc721'), "Rate class for token not configured");            
        });

        it('test conversions', async function () {
            await engine.updateEnabled(true);
            await engine.updateRateClass([minter], [1]);
            var supply1 = await engine.getRate(0, minter, [1], 'erc721');
            assert.equal(supply1-web3.utils.toBN('1000000000000000000000'), 0);
            var supply2 = await engine.getRate(supply1, minter, [1], 'erc721');;
            assert.equal(supply2-web3.utils.toBN('999307093033803327000'), 0);
            await engine.updateRateClass([minter], [2]);
            var supply3 = await engine.getRate(web3.utils.toBN('1999307093033803327000'), minter, [1], 'erc721');
            assert.equal(supply3-web3.utils.toBN('1994464418876877052'), 0);
        });
    });

});