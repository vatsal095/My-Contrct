pragma solidity 0.8.0;
contract test {
    uint256 public num;
    address  public _address;
    uint256 public value;

    function _test(uint256 _num) public payable {
        num =2*_num;
        _address = msg.sender;
        value = msg.value;
    }

}
contract delegatecall  {
    uint256 public num;
    uint256 public _address;// sender 
    uint256 public value;

    function testcall(address _address, uint256 value) external payable {
        // (bool success, bytes memory data) = _address.delegatecall(abi.encodeWithSignature("_test(uint256)", value));
        // require(success,"delegations fail");
        (bool success, bytes memory data) = _address.delegatecall(abi.encodeWithSelector(test._test.selector,value));
    }

}
