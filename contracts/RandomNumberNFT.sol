// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
contract RandomNumberNFT is VRFConsumerBase, Ownable {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    event Received(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Rinkeby
     * LINK token address: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * Key Hash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     * Fee: 0.1 LINK
     * 
     * Network: Ethereum
     * LINK token address: 0x514910771AF9Ca656af840dff83E8264EcF986CA
     * Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * Key Hash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     * Fee: 2 LINK
     */
    constructor() 
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(getBalanceInLink() >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    function getBalanceInLink() public view onlyOwner returns (uint256) {
       return LINK.balanceOf(address(this));
    }

    function withdrawLINK(address payable _recipient) external onlyOwner {
      uint256 amount = getBalanceInLink();
      (bool success, ) = payable(_recipient).call{value: amount}("");
      require(success, "Transaction failed");
      emit Withdraw(_recipient, amount);
    }
}
