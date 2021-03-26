var User = artifacts.require("./User.sol");
var Manager = artifacts.require("./Manager.sol");
var MakerFactory = artifacts.require("./MakerFactory.sol");
var MarketFactory = artifacts.require("./MarketFactory.sol");
var Router = artifacts.require("./Router.sol");

module.exports = async function (deployer) {
    await deployer.deploy(Manager, "owner_address");
    await deployer.deploy(MakerFactory);
    await deployer.deploy(MarketFactory);
    await deployer.deploy(User, Manager.address, "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c");
    await deployer.deploy(Router, Manager.address);
    const manager = await Manager.deployed();
    await manager.notifyTaker(User.address);
    await manager.notifyRouter(Router.address);
};