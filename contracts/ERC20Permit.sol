pragma solidity >=0.5.15  <=0.5.17;

import './library/SafeMath.sol';
import './interface/IERC20.sol';
import './library/SignatureDecode.sol';

contract ERC20Permit is IERC20 {
    using SafeMath for uint;

    string public name = 'YFX V1';
    string public symbol = 'YFX-V1';
    uint public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    string public constant permitName = "YFX";
    string public constant version = "1";
    //bytes32 public constant PERMIT_TYPEHASH = 'Permit(address sender,address spender,uint256 nonce,uint256 value)';
    bytes32 public constant PERMIT_TYPEHASH = 0x17ce4ae5fffa9d365170c0bae7f195be91c0ab405d6a4b0da0e32653ab8f3668;
    // EIP712 niceties
    bytes32 public DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;
    uint256 public chainId;

    constructor(uint256 _chainId) public {
        chainId = _chainId;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(permitName)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        require(to != address(0), "ERC20: mint to the zero address");
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(from != address(0), "ERC20: _burn from the zero address");
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) internal {
        require(owner != address(0), "ERC20: owner is the zero address");
        require(spender != address(0), "ERC20: spender is the zero address");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        require(from != address(0), "ERC20: _transfer from the zero address");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(from != address(0), "ERC20: transferFrom from the zero address");
        if (allowance[from][msg.sender] != uint(- 1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address _sender, address _spender, uint256 _nonce, uint256 _value, bytes calldata _sign) external {
        require(_sender != address(0), "ERC20: sender is the zero address");
        require(_spender != address(0), "ERC20: spender is the zero address");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, _sender, _spender, _nonce, _value))
            )
        );

        (bytes32 _r, bytes32 _s,uint8 _v) = SignatureDecode.decode(_sign);

        require(_sender == ecrecover(digest, _v, _r, _s));
        require(_nonce == nonces[_sender]++);

        _approve(_sender, _spender, _value);
    }
}
