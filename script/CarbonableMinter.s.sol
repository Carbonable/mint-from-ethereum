// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CarbonableMinter} from "src/CarbonableMinter.sol";

contract CarbonableMinterScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new CarbonableMinter(1, address(1));
        vm.stopBroadcast();
    }
}
