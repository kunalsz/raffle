// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test{
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 raffleFee;
    uint256 interval;
    bytes32 keyHash;
    uint256 subID;
    uint32 callbackGasLimit;
    address vrfCoordinator;

    //making a test PLAYER address from a string
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() external {
        //setup the deployer obj
        DeployRaffle deployer = new DeployRaffle();
        //returns 2 obj
        (raffle,helperConfig) = deployer.deployContract();

        //define all the starting params
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        raffleFee = config.raffleFee;
        interval = config.interval;
        keyHash = config.keyHash;
        subID = config.subID;
        vrfCoordinator = config.vrfCoordinator;
        callbackGasLimit = config.callbackGasLimit;

    }

    //test if the raffleState is open when raffle starts
    function testRaffleStateOpen() public view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}