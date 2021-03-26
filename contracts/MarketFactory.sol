pragma solidity >=0.5.15  <=0.5.17;

import "./Market.sol";

contract MarketFactory {
    event CreateMarket(address market);

    function createMarket(address manager) external returns (address){
        Market market = new Market(manager);
        emit CreateMarket(address(market));
        return address(market);
    }
}
