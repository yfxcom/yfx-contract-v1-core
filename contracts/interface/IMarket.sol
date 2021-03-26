pragma solidity >=0.5.15  <=0.5.17;

interface IMarket {
    function open(address _taker, address inviter, uint256 minPrice, uint256 maxPrice, uint256 margin, uint256 leverage, int8 direction) external returns (uint256 id);
    function close(address _taker, uint256 id, uint256 minPrice, uint256 maxPrice) external;
    function openCancel(address _taker, uint256 id) external;
    function closeCancel(address _taker, uint256 id) external;
    function priceToOpen(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external;
    function priceToClose(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external;
    function priceToOpenCancel(uint256 id) external;
    function priceToCloseCancel(uint256 id) external;
    function liquidity(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external;
    function depositMargin(address _taker, uint256 _id, uint256 _value) external;

    function getTakerOrderlist(address _taker) external view returns (uint256[] memory);
    function getByID(uint256 id) external view returns (bytes memory);

    function clearAnchorRatio() external view returns (uint256);
    function clearAnchorRatioDecimals() external view returns (uint256);
}
