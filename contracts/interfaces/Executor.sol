// SPDX-License-Identifier: MIT

pragma solidity 0.6.4;

interface Executor {
    function execute(
        uint256,
        uint256,
        uint256,
        uint256
    ) external;
}