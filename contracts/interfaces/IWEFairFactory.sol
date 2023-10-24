// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IWEFairFactory {
    function feeTo() external view returns (address);

    function transferSigner() external view returns (address);
}
