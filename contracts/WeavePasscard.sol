// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interface/nft.sol";

contract WeavePasscard is NFT, ERC721("Weave6 Genesis Pass", "WGP") {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 280;
    address public _launchpadAddress;

    Counters.Counter public tokenIds;

    constructor(address launchpadAddress) {
        _launchpadAddress = launchpadAddress;
        // start with one, if you want start with zero, comment this line
        tokenIds.increment();
    }

    function mint(
        address to,
        uint256 amount
    ) public override returns (uint256[] memory) {
        require(msg.sender == _launchpadAddress, "Only launchpad can mint");

        // only mint in zeta-testnet
        require(amount > 0, "Amount must be greater than 0");

        require(
            tokenIds.current() + amount <= MAX_SUPPLY,
            "Exceeds MAX_SUPPLY"
        );

        uint256[] memory ids = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = tokenIds.current();
            ids[i] = tokenId;
            _safeMint(to, tokenId);
            tokenIds.increment();
        }

        return ids;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }
}
