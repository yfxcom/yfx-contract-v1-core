pragma solidity >=0.5.15  <=0.5.17;

interface IFactory {
    function getMarket(uint256 indexPrice, address clearAnchor) external view returns (address);
    function getMaker(uint256 indexPrice, address clearAnchor) external view returns (address);

    function getMarketByMaker(address maker) external view returns (address);
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketClearAnchor(address maker) external view returns (address);
    function getMakerClearAnchor(address maker) external view returns (address);

}
