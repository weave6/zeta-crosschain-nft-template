// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface NFT {
    function mint(
        address to,
        uint256 amount
    ) external returns (uint256[] memory);
}
