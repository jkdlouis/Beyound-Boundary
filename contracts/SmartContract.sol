// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./RandomNumberNFT.sol";

contract SmartContract is ERC721, Ownable, ReentrancyGuard, RandomNumberNFT {
  using Strings for uint256;
  using Counters for Counters.Counter;
  using ECDSA for bytes32;
  using SignatureChecker for address;

  event Received(address indexed sender, uint256 amount);
  event Buy(address indexed buyer, uint256 amount);
  event VerifierSet(address indexed preVerifier, address indexed newVerifier);
  event Withdraw(address indexed recipient, uint256 amount);

  Counters.Counter private tokenId;

  bool public isSaleActive = true;

  string public baseExtension = ".json";
  string public baseTokenURI;

  uint256 public listingPrice = 0.01 ether;
  uint256 public maxSupply = 1000;
  uint256 public nftLimitPerAddress = 3;

  address public verifier;

  mapping(address => uint256) public addressNftBalance;

  // domain separators
  // keccak256("bb-nfts.access.is-whitelisted(address)")
  bytes32 internal constant DS_IS_WHITELISTED = 0x9ab6299e562ce2a1eece2b7dc9f6af11cf4064bfb33bbc3ef71035f1ad89af58;

  constructor(
    string memory _baseTokenURI,
    address _verifier
    ) 
    // Remember to change contract name here
    ERC721("Smart Contract", "SC")
    {
     baseTokenURI = _baseTokenURI; 
     verifier = _verifier;
     emit VerifierSet(address(0), _verifier);
  }

  function getTotalSupply() public view returns (uint256) {
    return tokenId.current();
  }

  // bytes memory _whitelistedSig
  function mint(address recipient) external payable nonReentrant returns (uint256) {
    require(isSaleActive == true, "Sale has been paused");
    // _verifyWhitelist(recipient, _whitelistedSig);
    require(msg.value >= listingPrice, "Not enough funds");
    require(tokenId.current() < maxSupply, "Sold Out");
    require(addressNftBalance[recipient] <= nftLimitPerAddress, "Max NFT per address reached");

    tokenId.increment();
    uint256 newId = tokenId.current();
    _safeMint(recipient, newId);
    addressNftBalance[recipient]++;
    emit Buy(recipient, addressNftBalance[recipient] * listingPrice);

    return newId;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseTokenURI = _newBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "NFT: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), baseExtension))
        : "";
  }

  receive() external payable {
      emit Received(msg.sender, msg.value);
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setIsSaleActive(bool _isSaleActive) external onlyOwner {
    isSaleActive = _isSaleActive;
  }

  function getBalance() public view onlyOwner returns(uint256) {
    return address(this).balance;
  }

  function withdrawToAddress(address payable _recipient, uint256 _amount) external onlyOwner {
    if (_amount == type(uint256).max) {
      _amount = getBalance();
    }
    (bool success, ) = payable(_recipient).call{value: _amount}("");
    require(success, "Transaction failed");
    emit Withdraw(_recipient, _amount);
  }

// Whitelist
  function setVerifier(address _newVerifier) external onlyOwner {
    emit VerifierSet(verifier, _newVerifier);
    verifier = _newVerifier;
  }

  function getWhitelistConstant() external pure returns (bytes32) {
    return DS_IS_WHITELISTED;
  }

  function _verifyWhitelist(address _account, bytes memory _whitelistedSig)
        internal view
    {
        require(
            _verifySignature(DS_IS_WHITELISTED, _account, _whitelistedSig),
            "Address is not whitelisted"
        );
    }

  function _verifySignature(bytes32 _domainSep, address _account, bytes memory _signature)
        internal view returns (bool)
    {
        return verifier.isValidSignatureNow(
            keccak256(abi.encode(_domainSep, _account)).toEthSignedMessageHash(),
            _signature
        );
    }
}
