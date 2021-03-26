pragma solidity >=0.5.15  <=0.5.17;

interface IMarketFactory {
    function createMarket(address manager) external returns (address);
}
