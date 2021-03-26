var User = artifacts.require("./User.sol");
var Manager = artifacts.require("./Manager.sol");
var MakerFactory = artifacts.require("./MakerFactory.sol");
var MarketFactory = artifacts.require("./MarketFactory.sol");
var Router = artifacts.require("./Router.sol");

module.exports = async function (deployer) {
    await deployer.deploy(Manager, "owner_address");
    await deployer.deploy(MakerFactory);
    await deployer.deploy(MarketFactory);
    await deployer.deploy(User, Manager.address, "0x5545153ccfca01fbd7dd11c0b23ba694d9509a6f");
    await deployer.deploy(Router, Manager.address);
    const manager = await Manager.deployed();
    await manager.notifyTaker(User.address);
    await manager.notifyRouter(Router.address);
};
