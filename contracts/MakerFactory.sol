pragma solidity >=0.5.15  <=0.5.17;

import "./Maker.sol";

contract MakerFactory {
    event CreateMaker(address maker);

    function createMaker(address manager) external returns (address){
        Maker maker = new Maker(manager);
        emit CreateMaker(address(maker));
        return address(maker);
    }
}