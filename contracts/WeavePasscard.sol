// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interface/nft.sol";

contract WeavePasscard is NFT, ERC721("Weave6 Genesis Pass", "WGP"), Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    address public _launchpadAddress;
    Counters.Counter public tokenIds;

    constructor(address launchpadAddress) {
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
    ) public override returns (uint256[] memory) {
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
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return
            "https://cloudflare-ipfs.com/ipfs/QmeGKjrqnVGz7T6AmVQLYBQfALoC6iP3X93Eqt3eYWpuj3";
    }
}
