// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

//deploy the raffle contract
contract DeployRaffle is Script{
    function run() public{}

    function deployContract() public returns(Raffle,HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        //local->anvil mock config
        //sep->gets sep config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.callbackGasLimit,
            config.subID,
            config.keyHash,
            config.raffleFee,
            config.interval,
            config.vrfCoordinator
        );
        vm.stopBroadcast();

        return (raffle,helperConfig);
    }

}
