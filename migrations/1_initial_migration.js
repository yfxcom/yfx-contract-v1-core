var User = artifacts.require("./User.sol");
var Manager = artifacts.require("./Manager.sol");
var Factory = artifacts.require("./Factory.sol");
var Router = artifacts.require("./Router.sol");

module.exports = async function(deployer) {
    await deployer.deploy(Manager,"owner_address");
    await deployer.deploy(User, Manager.address, "TNUC9Qb1rRpS5CbWLmNMxXBjyFoydXjWFR");
    await deployer.deploy(Factory, Manager.address);
    await deployer.deploy(Router, Manager.address, Factory.address);
    const manager = await Manager.deployed();
    await manager.notifyFactory(Factory.address);
    await manager.notifyTaker(User.address);
    await manager.notifyRouter(Router.address);
};
