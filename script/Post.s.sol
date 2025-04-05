// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import { PostFactory } from "../src/PostFactory.sol";
import { Script, console } from "forge-std/Script.sol";

contract PostScript is Script {
    address private relayer;
    address private identityVerificationHub;

    PostFactory public postFactory;

    function setUp() public {
        relayer = 0xf87319AF1FA7619375e82A9594444F825a30b85E;
        identityVerificationHub = 0x3e2487a250e2A7b56c7ef5307Fb591Cc8C83623D;
    }

    function run() public {
        vm.startBroadcast();
        postFactory = new PostFactory(relayer, /* relayer */ identityVerificationHub /* identityVerificationHub */ );
        vm.stopBroadcast();
    }
}
