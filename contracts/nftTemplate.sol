// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@zetachain/protocol-contracts/contracts/evm/tools/ZetaInteractor.sol";
import "@zetachain/protocol-contracts/contracts/evm/interfaces/ZetaInterfaces.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract nftTemplate is
    ZetaInteractor,
    ZetaReceiver,
    ERC721("Cross Chain NFT IN ZETA", "CCNIZ")
{
    error InvalidMessageType();

    event CrossChainNFTEvent(uint256, address, address);
    event CrossChainNFTRevertedEvent(uint256, address, address);

    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter public tokenIds;
    bytes32 public constant CROSS_CHAIN_WEAVE_MESSAGE_TYPE =
        keccak256("CROSS_CHAIN_CROSS_CHAIN_NFT_WEAVE");
    ZetaTokenConsumer private immutable _zetaConsumer;
    IERC20 internal immutable _zetaToken;

    address public _launchpadAddress;

    constructor(
        address connectorAddress,
        address zetaTokenAddress,
        address zetaConsumerAddress,
        address launchpadAddress
    ) ZetaInteractor(connectorAddress) {
        _zetaToken = IERC20(zetaTokenAddress);
        _zetaConsumer = ZetaTokenConsumer(zetaConsumerAddress);

        _launchpadAddress = launchpadAddress;
        // start with one, if you want start with zero, comment this line
        tokenIds.increment();
    }

    function changeLaunchpadAddress(address launchpadAddress) public onlyOwner {
        _launchpadAddress = launchpadAddress;
    }

    function mint(
        address to,
        uint256 amount
    ) public returns (uint256[] memory) {
        // only mint in zeta-testnet
        //require(block.chainid == 7001);
        require(msg.sender == _launchpadAddress, "Only launchpad can mint");
        require(amount > 0, "Amount must be greater than 0");

        uint256[] memory ids = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = tokenIds.current();
            ids[i] = tokenId;
            _safeMint(to, tokenId);
            tokenIds.increment();
        }

        return ids;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory uri = _baseURI();

        return
            bytes(uri).length > 0
                ? string(abi.encodePacked(uri, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal pure override returns (string memory) {
        return
            "https://bafybeib5ix2dtu3occzadsyjsjdka6z6mjy7jsphs45eiga74dzyfpb3xq.ipfs.w3s.link/genesis_pass_";
    }

    function _mintId(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId);
    }

    function _burnTokenByTokenId(uint256 tokenId) internal {
        _burn(tokenId);
    }

    function sendMessage(
        uint256 destinationChainId,
        uint256 token,
        address to
    ) external payable {
        if (!_isValidChainId(destinationChainId))
            revert InvalidDestinationChainId();

        require(
            _isApprovedOrOwner(_msgSender(), token),
            "Caller is not owner nor approved"
        );

        uint256 crossChainGas = 2 * (10 ** 18);
        uint256 zetaValueAndGas = _zetaConsumer.getZetaFromEth{
            value: msg.value
        }(address(this), crossChainGas);
        _zetaToken.approve(address(connector), zetaValueAndGas);

        _burnTokenByTokenId(token);

        connector.send(
            ZetaInterfaces.SendInput({
                destinationChainId: destinationChainId,
                destinationAddress: interactorsByChainId[destinationChainId],
                destinationGasLimit: 300000,
                message: abi.encode(
                    CROSS_CHAIN_WEAVE_MESSAGE_TYPE,
                    token,
                    msg.sender,
                    to
                ),
                zetaValueAndGas: zetaValueAndGas,
                zetaParams: abi.encode("")
            })
        );
    }

    function onZetaMessage(
        ZetaInterfaces.ZetaMessage calldata zetaMessage
    ) external override isValidMessageCall(zetaMessage) {
        (bytes32 messageType, uint256 token, address sender, address to) = abi
            .decode(zetaMessage.message, (bytes32, uint256, address, address));

        if (messageType != CROSS_CHAIN_WEAVE_MESSAGE_TYPE)
            revert InvalidMessageType();

        _mintId(to, token);

        emit CrossChainNFTEvent(token, sender, to);
    }

    function onZetaRevert(
        ZetaInterfaces.ZetaRevert calldata zetaRevert
    ) external override isValidRevertCall(zetaRevert) {
        (bytes32 messageType, uint256 token, address sender, address to) = abi
            .decode(zetaRevert.message, (bytes32, uint256, address, address));

        if (messageType != CROSS_CHAIN_WEAVE_MESSAGE_TYPE)
            revert InvalidMessageType();

        _mintId(to, token);

        emit CrossChainNFTRevertedEvent(token, sender, to);
    }
}
