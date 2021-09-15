// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

interface IAggregator {
  function latestAnswer() external view returns (int256);

    function latestRoundData()
        external
        view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}