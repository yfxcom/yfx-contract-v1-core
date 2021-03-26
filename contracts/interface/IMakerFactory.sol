pragma solidity >=0.5.15  <=0.5.17;

interface IMakerFactory {
    function createMaker(address manager) external returns (address);
}
