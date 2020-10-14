 
pragma solidity ^0.5.12;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "openzeppelin-solidity/contracts/drafts/Counters.sol";

/* * @title non fungible token representing a digital asset.
 */
contract Accert is ERC721Full {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    constructor() ERC721Full("TOKEN", "VAT") public {}

    function tokenize(string memory _swarmHash) public {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _swarmHash);
    }
}
