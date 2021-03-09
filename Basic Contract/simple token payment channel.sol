pragma solidity ^0.4.18;

contract Token {
  function transfer(address, uint256) public returns (bool) {}
  function transferFrom(address, address, uint256) public returns (bool) {}
}

contract TokenPaymentChannel {
  address owner;
  mapping(bytes32 => Channel) channels;

  struct Channel {
    address tokenAddress;
    uint256 tokenAmount;
    State state;
    address participant;
    uint256 expirationBlock;
  }

  enum State {
    Open,
    Pending,
    Closed
  }

  function TokenPaymentChannel() public {
    owner = msg.sender;
  }
  function openChannel(address _tokenAddress, uint256 _tokenAmount, uint8 _v, bytes32 _r, bytes32 _s) 
    public returns (bytes32 channelHash) 
  {
    bytes32 _channelHash = keccak256(_tokenAddress, _tokenAmount, msg.sender);
    require(Token(_tokenAddress).transferFrom(msg.sender, this, _tokenAmount));
    channels[_channelHash] = Channel(_tokenAddress, _tokenAmount, State.Open, msg.sender, 0);
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", _channelHash), _v, _r, _s) == owner);
    return _channelHash;
  }


  
  function closeChannel(bytes32 _channelHash, uint256 _refundAmount, bytes32 _channelCloseHash, uint8 _v, bytes32 _r, bytes32 _s) 
    public onlyParticipant(_channelHash) inState(_channelHash, State.Open) returns (bool success)
  {
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", _channelCloseHash), _v, _r, _s) == owner);
    bytes32 _hash = keccak256(_channelHash, _refundAmount);
    Channel storage _channel = channels[_channelHash];
    _channel.state = State.Closed;
    require(_channelCloseHash == _hash || (_channelCloseHash == _channelHash && _refundAmount == _channel.tokenAmount));
    require(Token(_channel.tokenAddress).transfer(_channel.participant, _refundAmount));
    require(Token(_channel.tokenAddress).transfer(owner, _channel.tokenAmount - _refundAmount));
    return true;
  }

  function voidChannel(bytes32 _channelHash, uint256 _refundAmount, bytes32 _channelCloseHash, uint8 _v, bytes32 _r, bytes32 _s) 
    public onlyParticipant(_channelHash) inState(_channelHash, State.Open) returns (bool success)
  {
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", _channelCloseHash), _v, _r, _s) == owner);
    bytes32 _hash = keccak256(_channelHash, _refundAmount);
    Channel storage _channel = channels[_channelHash];
    require(_channelCloseHash == _hash || (_channelCloseHash == _channelHash && _refundAmount == _channel.tokenAmount));
    _channel.expirationBlock = block.number + 180000; // Roughly a month
    _channel.state = State.Pending;
    return true;
  }

  function finalizeVoidChannel(bytes32 _channelHash, uint256 _refundAmount, bytes32 _channelCloseHash, uint8 _v, bytes32 _r, bytes32 _s) 
    public onlyParticipant(_channelHash) inState(_channelHash, State.Pending) returns (bool success)
  {
    require(ecrecover(keccak256("\x19Ethereum Signed Message:\n32", _channelCloseHash), _v, _r, _s) == owner);
    bytes32 _hash = keccak256(_channelHash, _refundAmount);
    Channel storage _channel = channels[_channelHash];
    require(_channelCloseHash == _hash || (_channelCloseHash == _channelHash && _refundAmount == _channel.tokenAmount));
    require(Token(_channel.tokenAddress).transfer(_channel.participant, _refundAmount));
    require(Token(_channel.tokenAddress).transfer(owner, _channel.tokenAmount - _refundAmount));
    _channel.state = State.Closed;
    return true;
  }
  function counterVoidChannel(bytes32 _channelHash, uint256 _refundAmount, bytes32 _channelCloseHash, uint8 _v, bytes32 _r, bytes32 _s) 
    public inState(_channelHash, State.Pending) returns (bool success)
  {
    return true;
  }

   /**
    @dev returns channel information
    @param _channelHash hash of channel
    */
  function channel(bytes32 _channelHash) public view returns (address, uint256, State, address) {
    Channel memory _channel = channels[_channelHash];
    return (_channel.tokenAddress, _channel.tokenAmount, _channel.state, _channel.participant);
  }

  function getChannelHash(address _tokenAddress, uint256 _tokenAmount, address _account) public view returns(bytes32) {
    return keccak256(_tokenAddress, _tokenAmount, _account);
  }

  function getChannelCloseHash(bytes32 _channelHash, uint256 _refundAmount) public view returns(bytes32) {
    return keccak256(_channelHash, _refundAmount);
  }


  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyParticipant(bytes32 _channelHash) {
    require(msg.sender == channels[_channelHash].participant);
    _;
  }

  modifier inState(bytes32 _channelHash, State _state) {
    require(channels[_channelHash].state == _state);
    _;
  }
}
