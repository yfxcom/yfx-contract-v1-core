pragma solidity >=0.5.15  <=0.5.17;

import './ERC20Permit.sol';
import './library/SignatureDecode.sol';

contract TradeToken is ERC20Permit {
    address public market;

    constructor(address _market, string memory _lpTokenName, uint256 chainId) public ERC20Permit(chainId){
        require(_market != address(0), "Maker:constructor _manager is zero address");
        market = _market;
        name = _lpTokenName;
        symbol = _lpTokenName;
    }

    modifier onlyMarket() {
        require(market == msg.sender, "insufficient permissions!");
        _;
    }

    function mint(address to, uint256 value) external onlyMarket returns (bool){
        require(to != address(0), "ERC20: mint to the zero address");
        _mint(to, value);
        return true;
    }

    function burn(address from, uint256 value) external returns (bool){
        require(from != address(0), "ERC20: burn from the zero address");
        require(balanceOf[from] >= value, 'TradeToken:burn Insufficient balance');
        _burn(from, value);
        return true;
    }
}
