// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BBRoyalty is ERC721, Ownable {
    string public _contractURI; 

    event Received(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    constructor(string memory _newContractURI) ERC721("BBRoyalty", "BBR") {
       _contractURI = _newContractURI;
    }

    receive() external payable {
      emit Received(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint256) {
      return address(this).balance;
    }

    function getAddress() external view returns(address) {
      return address(this);
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _newContractURI) external onlyOwner {
      _contractURI = _newContractURI;
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