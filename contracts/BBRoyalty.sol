// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BBRoyalty is ERC721, Ownable {
    string public contractURIjson; 

    event Withdraw(address indexed recipient, uint256 amount);

    constructor(string memory _contractURI) ERC721("BBRoyalty", "BBR") {
       contractURIjson = _contractURI;
    }
    
    function contractURI() public view returns (string memory) {
        return contractURIjson;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
      contractURIjson = _contractURI;
    }

    function withdrawToAddress(address payable _recipient, uint256 _amount) external onlyOwner {
    if (_amount == type(uint256).max) {
      _amount = address(this).balance;
    }
    (bool success, ) = payable(_recipient).call{value: _amount}("");
    require(success, "Transaction failed");
    emit Withdraw(_recipient, _amount);
  }
}