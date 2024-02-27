// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/nft.sol";

contract Launchpad is ReentrancyGuard, Ownable {
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
        require(_isAdmin[msg.sender]);
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

    event UpdateLaunchpadEvent(
        address token,
        address receiver,
        uint256 tokenPrice,
        uint256 maxAmount,
        address operationAddress,
        uint256 launchpadId
    );

    event AdminAddEvent(address operationAddress, address adminAddress);
    event AdminRemoveEvent(address operationAddress, address adminAddress);

    event SwitchEndEvent(address operationAddress, uint256 launchpadId);
    event SwitchWhiteListEvent(
        address operationAddress,
        uint256 launchpadId,
        bool onlyWhitelist
    );
    event AddWhitelistUser(
        address operationAddress,
        uint256 launchpadId,
        address user
    );

    event RemoveWhitelistUser(
        address operationAddress,
        uint256 launchpadId,
        address user
    );

    event UpdateTimeEvent(
        uint256 launchpadId,
        address operationAddress,
        uint256 startTimestamp,
        uint256 endTimestamp
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
        uint256 maxAmountPerWallet
    ) public onlyAdmin {
        launchInfo storage info = _launchpad[launchpadId];

        info.token = token;
        info.receiver = receiver;
        info.tokenPrice = tokenPrice;
        info.maxAmount = maxAmount;
        info.maxAmountPerWallet = maxAmountPerWallet;

        emit UpdateLaunchpadEvent(
            token,
            receiver,
            tokenPrice,
            maxAmount,
            msg.sender,
            launchpadId
        );
    }

    function updateTime(
        uint256 launchpadId,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) public onlyAdmin {
        launchInfo storage info = _launchpad[launchpadId];
        info.startTimestamp = startTimestamp;
        info.endTimestamp = endTimestamp;

        emit UpdateTimeEvent(
            launchpadId,
            msg.sender,
            startTimestamp,
            endTimestamp
        );
    }

    function mint(
        uint256 launchpadId,
        uint256 amount
    ) public payable nonReentrant returns (uint256[] memory) {
        require(_launchpad[launchpadId].isEnded, "Launchpad is ended");
        launchInfo storage info = _launchpad[launchpadId];

        if (info.onlyWhitelist) {
            require(
                _launchpad[launchpadId]._isUserWhitelisted[msg.sender],
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
            "Amount is reached max amount"
        );

        require(
            info._userAmount[msg.sender] + amount <= info.maxAmountPerWallet,
            "Amount is greater than max amount per wallet"
        );

        // uint256 value = msg.value;

        uint256 mint_price = info.tokenPrice * amount;

        payable(info.receiver).transfer(mint_price);
        payable(msg.sender).transfer(msg.value - mint_price);

        info.mintedAmount += amount;

        info._userAmount[msg.sender] += amount;
        emit Mint(launchpadId, msg.sender, amount);
        return NFT(info.token).mint(msg.sender, amount);
    }

    function addAdmin(address admin) public onlyAdmin {
        _isAdmin[admin] = true;
        emit AdminRemoveEvent(msg.sender, admin);
    }

    function removeAdmin(address admin) public onlyAdmin {
        _isAdmin[admin] = false;
        emit AdminRemoveEvent(msg.sender, admin);
    }

    function switchEndLaunchpad(uint256 launchpadId) public onlyAdmin {
        _launchpad[launchpadId].isEnded = !_launchpad[launchpadId].isEnded;
        emit SwitchEndEvent(msg.sender, launchpadId);
    }

    function switchOnlyWhiteList(uint256 launchpadId) public onlyAdmin {
        _launchpad[launchpadId].onlyWhitelist = !_launchpad[launchpadId]
            .onlyWhitelist;

        emit SwitchWhiteListEvent(
            msg.sender,
            launchpadId,
            !_launchpad[launchpadId].onlyWhitelist
        );
    }

    function addWhitelistUser(
        uint256 launchpadId,
        address user
    ) public onlyAdmin {
        _launchpad[launchpadId]._isUserWhitelisted[user] = true;
        emit AddWhitelistUser(msg.sender, launchpadId, user);
    }

    function removeWhitelistUser(
        uint256 launchpadId,
        address user
    ) public onlyAdmin {
        _launchpad[launchpadId]._isUserWhitelisted[user] = false;

        emit RemoveWhitelistUser(msg.sender, launchpadId, user);
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
