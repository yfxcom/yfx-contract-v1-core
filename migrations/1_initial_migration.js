var User = artifacts.require("./User.sol");
var Manager = artifacts.require("./Manager.sol");
var MakerFactory = artifacts.require("./MakerFactory.sol");
var MarketFactory = artifacts.require("./MarketFactory.sol");
var Router = artifacts.require("./Router.sol");

module.exports = async function (deployer) {
    await deployer.deploy(Manager, "owner_address");
    await deployer.deploy(MakerFactory);
    await deployer.deploy(MarketFactory);
    await deployer.deploy(User, Manager.address, "0xe91d153e0b41518a2ce8dd3d7944fa863463a97d", 1);
    await deployer.deploy(Router, Manager.address, 1);
    const manager = await Manager.deployed();
    await manager.notifyTaker(User.address);
    await manager.notifyRouter(Router.address);
    await manager.unpause();
};