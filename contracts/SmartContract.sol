// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./VRFv2Consumer.sol";

contract SmartContract is ERC721, ReentrancyGuard, VRFv2Consumer {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using SignatureChecker for address;

    event Received(address indexed sender, uint256 amount);
    event Buy(address indexed buyer, uint256 amount);
    event VerifierSet(address indexed preVerifier, address indexed newVerifier);
    event Withdraw(address indexed recipient, uint256 amount);
    event SetTokenURI(address indexed sender, uint256 tokenId, string tokenURI);

    bool public isSaleActive = true;

    string public baseExtension = ".json";
    string public baseTokenURI;

    uint256 public listingPrice = 0.01 ether;
    uint256 public maxSupply = 1000;
    uint256 public nftLimitPerAddress = 3;

    address public verifier;

    Counters.Counter private tokenId;

    mapping(uint256 => address) public tokenOwnedByAddress;
    mapping(address => uint256) public addressNftBalance;
    mapping(uint256 => string) private _tokenURIs;

    // domain separators
    // keccak256("bb-nfts.access.is-whitelisted(address)")
    bytes32 internal constant DS_IS_WHITELISTED =
        0x9ab6299e562ce2a1eece2b7dc9f6af11cf4064bfb33bbc3ef71035f1ad89af58;

    constructor(
        string memory _baseTokenURI,
        address _verifier,
        uint64 subscriptionId
    )
        // Remember to change contract name here
        ERC721("Smart Contract", "SC")
    {
        baseTokenURI = _baseTokenURI;
        verifier = _verifier;
        emit VerifierSet(address(0), _verifier);

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_subscriptionId = subscriptionId;
    }

    function getTotalSupply() public view returns (uint256) {
        return tokenId.current();
    }

    // bytes memory _whitelistedSig
    function mint() external payable nonReentrant returns (uint256) {
        require(isSaleActive == true, "Sale has been paused");
        // _verifyWhitelist(msg.sender, _whitelistedSig);
        require(msg.value >= listingPrice, "Not enough funds");
        require(getTotalSupply() < maxSupply, "Sold Out");
        require(
            addressNftBalance[msg.sender] < nftLimitPerAddress,
            "Max NFT per address reached"
        );

        tokenId.increment();
        uint256 newId = getTotalSupply();
        _safeMint(msg.sender, newId);
        tokenOwnedByAddress[newId] = msg.sender;
        addressNftBalance[msg.sender]++;
        emit Buy(msg.sender, addressNftBalance[msg.sender] * listingPrice);

        return newId;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    modifier isTokenIdExist(uint256 _tokenId) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
        _;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        isTokenIdExist(_tokenId)
        returns (string memory)
    {
        string memory _tokenURI = _tokenURIs[_tokenId];

        if (bytes(_tokenURI).length > 0) {
            return convertTokenURI(_tokenURI, _tokenId);
        }

        return convertTokenURI(_baseURI(), _tokenId);
    }

    function convertTokenURI(string memory _tokenURI, uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_tokenURI, _tokenId.toString(), baseExtension)
            );
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        isTokenIdExist(_tokenId)
    {
        require(
            tokenOwnedByAddress[_tokenId] == msg.sender,
            "User does not own NFT"
        );
        _tokenURIs[_tokenId] = _tokenURI;
        emit SetTokenURI(msg.sender, _tokenId, _tokenURI);
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setIsSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawToAddress(address payable _recipient, uint256 _amount)
        external
        onlyOwner
    {
        if (_amount == type(uint256).max) {
            _amount = getBalance();
        }
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Transaction failed");
        emit Withdraw(_recipient, _amount);
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Renounce ownership is not allowed");
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
        internal
        view
    {
        require(
            _verifySignature(DS_IS_WHITELISTED, _account, _whitelistedSig),
            "Address is not whitelisted"
        );
    }

    function _verifySignature(
        bytes32 _domainSep,
        address _account,
        bytes memory _signature
    ) internal view returns (bool) {
        return
            verifier.isValidSignatureNow(
                keccak256(abi.encode(_domainSep, _account))
                    .toEthSignedMessageHash(),
                _signature
            );
    }
}
