const Company = artifacts.require("Company");
const truffleAssert = require('truffle-assertions');
contract("Company", (accounts) => {
    const user1 = accounts[0];
    const user2 = accounts[1];
    const user3 = accounts[2];
    console.log(accounts);
    it("1. should be able to set the right master", async () => {
        const company = await Company.deployed();
        assert.deepEqual(await company.getMaster(), user1);
    });
    it("2. only master should be able to add owner", async () => {
        const company = await Company.deployed();
        await truffleAssert.reverts(
            company.addOwner(user1, {from: user2}),
        );
    });
    it("3. master should be able to add owner", async() => {
        const company = await Company.deployed();
        const tx = await company.addOwner(user1);
        truffleAssert.eventEmitted(tx, "OwnerAddition", (ev) => {
            return ev.owner == user1;
        })

        assert.deepEqual(await company.getOwners(), [user1]);
    });
    it("4. should be able to check owner", async () => {
        const company = await Company.deployed();
        await company.addOwner(user1);
        
        assert.equal(await company.checkIfOwner(user1), true);
    });
    it("5. only master should be able to remove owners", async () => {
        const company = await Company.deployed();

        await truffleAssert.reverts(
            company.removeOwner(user1, {from: user2}),
            //"Only Master has the right to call"
        );
    });
    it("6. master should be able to remove owners", async () => {
        const company = await Company.deployed();

        const tx = await company.removeOwner(user1);
        truffleAssert.eventEmitted(tx, "OwnerRemoval", (ev) => {
            return ev.owner == user1;
        });
        assert.deepEqual(await company.getOwners(), []);
    });
    it("7. master should be able to send his share to owners", async() => {
        const company = await Company.deployed();

        await company.addOwner(user2);

        assert.equal(await company.getShare(user2), 5000000);

        const tx1 = await company.addShare(user2, 1000);
        truffleAssert.eventEmitted(tx1, "Transfer", (ev) => {
            return ev.receiver == user2 && ev.amount == 1000
        });

        const user2Share = await company.getShare(user2);

        assert.equal(user2Share.toString(), 5001000);
    });
    it("8. should not be able to use addShare() to transfer share to non-admins(normal-users)", async() => {
        const company = await Company.deployed();

        await truffleAssert.reverts(
            company.addShare(user3, 1000),
        );
    });
    it("9. should be able to use giveShare() to transfer share to anyone", async () => {
        const company = await Company.deployed();

        const tx = await company.giveShare(user3,  1500);
        truffleAssert.eventEmitted(tx, "Transfer", (ev) => {
            return ev.receiver == user3 && ev.amount == 1500;
        });

        assert.equal(await company.getShare(user3), 1500);
    });
})