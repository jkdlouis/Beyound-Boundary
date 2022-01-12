// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";


contract SmartContract is ERC721, Ownable, ReentrancyGuard, RoyaltiesV2Impl {
  using Strings for uint256;
  using Counters for Counters.Counter;
  using ECDSA for bytes32;
  using SignatureChecker for address;

  event Buy(address indexed buyer, uint256 amount);
  event VerifierSet(address indexed preVerifier, address indexed newVerifier);
  event Withdraw(address indexed recipient, uint256 amount);

  Counters.Counter private tokenId;

  bool public pause = false;

  string public baseExtension = ".json";
  string public baseTokenURI;

  uint256 public listingPrice = 0.25 ether;
  uint256 public maxSupply = 1000;
  uint256 public nftLimitPerAddress = 3;

  address public verifier;

  mapping(address => uint256) public addressNftBalance;

  // domain separators
  // keccak256("bb-nfts.access.is-whitelisted(address)")
  bytes32 internal constant DS_IS_WHITELISTED = 0x9ab6299e562ce2a1eece2b7dc9f6af11cf4064bfb33bbc3ef71035f1ad89af58;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor(
    string memory _baseTokenURI,
    address _verifier
    ) 
    ERC721("Smart Contract", "SC") 
    Ownable()
    ReentrancyGuard()
    {
     baseTokenURI = _baseTokenURI; 
     verifier = _verifier;
     emit VerifierSet(address(0), _verifier);
  }

  function getTotalSupply() external view returns (uint256) {
    return tokenId.current();
  }

  function mint(address recipient, bytes memory _whitelistedSig) external payable nonReentrant returns (uint256) {
    require(pause == false, "Sale has been paused");
    _verifyWhitelist(recipient, _whitelistedSig);
    require(msg.value >= listingPrice, "Not enough funds");
    require(tokenId.current() < maxSupply, "Sold Out");
    require(addressNftBalance[recipient] <= nftLimitPerAddress, "Max NFT per address reached");

    tokenId.increment();
    uint256 newId = tokenId.current();
    _safeMint(recipient, newId);
    addressNftBalance[recipient]++;
    // 1000 percentageBasisPoints = 10%
    setRoyalties(newId, payable(address(this)), 1000);
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

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pauseSale(bool _pause) external onlyOwner {
    pause = _pause;
  }

// Whitelist
  function setVerifier(address _newVerifier) external onlyOwner {
    emit VerifierSet(verifier, _newVerifier);
    verifier = _newVerifier;
  }

  function withdrawToAddress(address payable _recipient, uint256 _amount) external onlyOwner {
    if (_amount == type(uint256).max) {
      _amount = address(this).balance;
    }
    (bool success, ) = payable(_recipient).call{value: _amount}("");
    require(success, "Transaction failed");
    emit Withdraw(_recipient, _amount);
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

// Royalty
  function setRoyalties(uint256 _tokenId, address payable _recipient, uint96 _percentageBasisPoints) internal {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _recipient;
    _saveRoyalties(_tokenId, _royalties);
  }

  function royaltyInfo(uint256 _tokenId) external view returns (address receiver,uint256 royaltyAmount) {
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if (_royalties.length > 0) {
      // 10000 percentageBasisPoints = 100%
      return (_royalties[0].account, (listingPrice * _royalties[0].value / 10000));
    }
    return (address(0), 0);
  }

  function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721) returns (bool) {
    if (_interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }

    if (_interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }

    return super.supportsInterface(_interfaceId);
  }
}
