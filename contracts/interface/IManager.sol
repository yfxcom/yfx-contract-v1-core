pragma solidity >=0.5.15  <=0.5.17;

interface IManager{
    function feeOwner() external view returns (address);
    function riskFundingOwner() external view returns (address);
    function poolFeeOwner() external view returns (address);
    function taker() external view returns (address);
    function checkSigner(address _signer)  external view returns(bool);
    function checkController(address _controller)  view external returns(bool);
    function checkRouter(address _router) external view returns(bool);
    function checkMarket(address _market) external view returns(bool);
    function checkMaker(address _maker) external view returns(bool);

    function cancelBlockElapse() external returns (uint256);
    function openLongBlockElapse() external returns (uint256);

    function paused() external returns (bool);

    function getMarket(uint256 indexPrice, address clearAnchor) external view returns (address);
    function getMaker(uint256 indexPrice, address clearAnchor) external view returns (address);

    function getMarketByMaker(address maker) external view returns (address);
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketClearAnchor(address maker) external view returns (address);
    function getMakerClearAnchor(address maker) external view returns (address);
}

