// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/nft.sol";

contract Launchpad is ReentrancyGuard {
    mapping(address => bool) _isAdmin;
    mapping(uint256 => launchInfo) public _launchpad;

    using Counters for Counters.Counter;
    Counters.Counter public _launchpadIds;

    struct launchInfo {
        Counters.Counter _ids;
        address token;
        address receiver;
        bool onlyWhitelist;
        mapping(address => bool) _isUserWhitelisted;
        uint256 tokenPrice;
        uint256 maxAmount;
        uint256 mintedAmount;
        mapping(address => uint256) _userAmount;
        uint256 maxAmountPerWallet;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool isEnded;
    }

    struct mintInfo {
        uint256 launchpadId;
        address token;
        address receiver;
        bool onlyWhitelist;
        uint256 tokenPrice;
        uint256 maxAmount;
        uint256 mintedAmount;
        uint256 maxAmountPerWallet;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool isEnded;
    }

    modifier onlyAdmin() {
        require(_isAdmin[msg.sender] == true);
        _;
    }

    event Mint(uint256 launchpadId, address user, uint256 amount);
    event CreateLaunchpadEvent(
        address token,
        address receiver,
        uint256 tokenPrice,
        uint256 maxAmount,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 launchpadId
    );

    constructor() {
        _isAdmin[msg.sender] = true;
    }

    function createLaunchpad(
        address token,
        address receiver,
        uint256 tokenPrice,
        uint256 maxAmount,
        uint256 maxAmountPerWallet,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool isStartWithZero,
        bool onlyWhitelist
    ) public onlyAdmin {
        uint256 launchpadId = _launchpadIds.current();
        _launchpadIds.increment();

        launchInfo storage info = _launchpad[launchpadId];

        if (!isStartWithZero) {
            info._ids.increment();
        }

        info.token = token;
        info.receiver = receiver;
        info.tokenPrice = tokenPrice;
        info.maxAmount = maxAmount;
        info.maxAmountPerWallet = maxAmountPerWallet;
        info.startTimestamp = startTimestamp;
        info.endTimestamp = endTimestamp;
        info.isEnded = false;
        info.onlyWhitelist = onlyWhitelist;

        emit CreateLaunchpadEvent(
            info.token,
            info.receiver,
            tokenPrice,
            maxAmount,
            startTimestamp,
            endTimestamp,
            launchpadId
        );
    }

    function updateLaunchpad(
        uint256 launchpadId,
        address token,
        address receiver,
        uint256 tokenPrice,
        uint256 maxAmount,
        uint256 maxAmountPerWallet,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool onlyWhitelist
    ) public onlyAdmin {
        launchInfo storage info = _launchpad[launchpadId];

        info.token = token;
        info.receiver = receiver;
        info.tokenPrice = tokenPrice;
        info.maxAmount = maxAmount;
        info.maxAmountPerWallet = maxAmountPerWallet;
        info.startTimestamp = startTimestamp;
        info.endTimestamp = endTimestamp;
        info.isEnded = false;
        info.onlyWhitelist = onlyWhitelist;
    }

    function mint(
        uint256 launchpadId,
        uint256 amount
    ) public payable nonReentrant returns (uint256[] memory) {
        require(_launchpad[launchpadId].isEnded == false, "Launchpad is ended");
        launchInfo storage info = _launchpad[launchpadId];

        if (info.onlyWhitelist) {
            require(
                _launchpad[launchpadId]._isUserWhitelisted[msg.sender] == true,
                "User is not whitelisted"
            );
        }

        require(
            block.timestamp >= info.startTimestamp &&
                block.timestamp <= info.endTimestamp,
            "Launchpad is not started or ended"
        );

        require(
            amount <= info.maxAmountPerWallet,
            "Amount is greater than max amount per wallet"
        );

        require(
            info.mintedAmount + amount <= info.maxAmount,
            "Amount is greater than max amount per wallet"
        );

        require(
            info._userAmount[msg.sender] + amount <= info.maxAmountPerWallet,
            "Amount is greater than max amount per wallet"
        );

        uint256 mint_price = info.tokenPrice * amount;
        require(mint_price <= msg.value);
        payable(info.receiver).transfer(mint_price);

        info.mintedAmount += amount;

        info._userAmount[msg.sender] += amount;
        emit Mint(launchpadId, msg.sender, amount);
        return NFT(info.token).mint(msg.sender, amount);
    }

    function addAdmin(address admin) public onlyAdmin {
        _isAdmin[admin] = true;
    }

    function removeAdmin(address admin) public onlyAdmin {
        _isAdmin[admin] = false;
    }

    function switchEndLaunchpad(uint256 launchpadId) public onlyAdmin {
        _launchpad[launchpadId].isEnded = !_launchpad[launchpadId].isEnded;
    }

    function switchOnlyWhiteList(uint256 launchpadId) public onlyAdmin {
        _launchpad[launchpadId].onlyWhitelist = !_launchpad[launchpadId]
            .onlyWhitelist;
    }

    function addWhitelistUser(
        uint256 launchpadId,
        address user
    ) public onlyAdmin {
        _launchpad[launchpadId]._isUserWhitelisted[user] = true;
    }

    function removeWhitelistUser(
        uint256 launchpadId,
        address user
    ) public onlyAdmin {
        _launchpad[launchpadId]._isUserWhitelisted[user] = false;
    }

    function isUserWhitelisted(
        uint256 launchpadId,
        address user
    ) public view returns (bool) {
        return _launchpad[launchpadId]._isUserWhitelisted[user];
    }

    function addWhitelistUsers(
        uint256 launchpadId,
        address[] memory users
    ) public onlyAdmin {
        for (uint i = 0; i < users.length; i++) {
            _launchpad[launchpadId]._isUserWhitelisted[users[i]] = true;
        }
    }

    function removeWhitelistUsers(
        uint256 launchpadId,
        address[] memory users
    ) public onlyAdmin {
        for (uint i = 0; i < users.length; i++) {
            _launchpad[launchpadId]._isUserWhitelisted[users[i]] = false;
        }
    }

    function queryMintInfo(
        uint256 launchpadId
    ) public view returns (mintInfo memory) {
        launchInfo storage info = _launchpad[launchpadId];
        return
            mintInfo(
                launchpadId,
                info.token,
                info.receiver,
                info.onlyWhitelist,
                info.tokenPrice,
                info.maxAmount,
                info.mintedAmount,
                info.maxAmountPerWallet,
                info.startTimestamp,
                info.endTimestamp,
                info.isEnded
            );
    }

    function mintedAmount(
        uint256 launchpadId,
        address user
    ) public view returns (uint256) {
        return _launchpad[launchpadId]._userAmount[user];
    }
}
