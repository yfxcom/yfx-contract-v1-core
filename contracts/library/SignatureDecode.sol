pragma solidity >=0.5.15  <=0.5.17;

library SignatureDecode {
    function decode(bytes memory signedString) internal pure returns (bytes32 r, bytes32 s, uint8 v){
        r = bytesToBytes32(slice(signedString, 0, 32));
        s = bytesToBytes32(slice(signedString, 32, 32));
        byte v1 = slice(signedString,64,1)[0];
        v = uint8(v1);
    }

    function slice(bytes memory data, uint start, uint len) internal pure returns (bytes memory){
        bytes memory b = new bytes(len);
        for (uint i = 0; i < len; i++) {
            b[i] = data[i + start];
        }
        return b;
    }

    function bytesToBytes32(bytes memory source) internal pure returns (bytes32 result){
        assembly{
            result := mload(add(source, 32))
        }
    }
}
