pragma solidity ^0.8.7;
contract functions {
    function func1() external view returns(uint,uint) {
        return(1, block.timestamp);
    }
    function func2() external view returns(uint,uint) {
        return(2, block.timestamp);
    }
    function getfun1() external pure returns(bytes memory){
        // abi.endcodeWithSignature("func1()")
        return abi.encodeWithSelector(this.func1.selector);
    }
    function getfun2() external pure returns(bytes memory){
        // abi.endcodeWithSignature("func2()")
        return abi.encodeWithSelector(this.func2.selector);
    }
}
contract multicall {
    function multi(address[] calldata target, bytes[] calldata data)
        external
        view
        returns(bytes[] memory) 
    {
            require(target.length == data.length,"both are not same");
            //this is how we can crete new bytes array with fix length 
            bytes[] memory results = new bytes[](data.length);

            for(uint i; i < target.length; i++)
            {
                /// here the function is the view so we don't want to change the state so we use static call insted of call function 
                (bool success, bytes memory result) = target[i].staticcall(data[i]);
                require(success,"call failed");
                results[i]=result;
            }
            return results;

    }
}
