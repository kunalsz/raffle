// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";

contract Raffle is VRFConsumerBaseV2Plus{
    // Errors
    error Raffle__NotEnoughETH();
    error Raffle__TransferFailed();
    error Raffle__NotOPEN();
    error Raffle_UpkeepNotNeeded(uint256 balance,uint256 playersLength,RaffleState raffleState);

    //creating enums to know the raffle state, to not let ppl enter during calculation
    enum RaffleState{
        OPEN,  //0
        CALCULATING //1
    }

    //immutable can only be declared in constructor or here
    uint16 private constant REQUEST_CONF = 3;
    uint32 private constant NUM_WORDS =1;
    uint256 private immutable i_raffleFee;
    uint256 private immutable i_interval; // interval bw raffles
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subID;
    uint32 private immutable i_callbackGasLimit;
    // array of address of all players in raffle
    address payable[] private s_players; 
    address payable private s_winner;
    uint256 private s_lastTimestamp;
    RaffleState private s_raffleState;

    // Events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);


    //vrfCoordinator address is the address from which we request the random num
    constructor(uint32 callbackGasLimit,uint256 subID,bytes32 keyHash, uint256 raffleFee,uint256 interval,address vrfCoordinator) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_raffleFee = raffleFee;
        i_interval = interval; //to get the current time
        s_lastTimestamp = block.timestamp;
        i_keyHash = keyHash;
        i_subID = subID;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    // FUNCTIONS

    //payable to give fees. Join the raffle
    function joinRaffle() public payable{

        //not using this statement as it require takes a lot of gas
        //require(msg.value >= i_raffleFee,"Not enough ETH"); 

        //instead we use this,custom errors with revert, more gas effficient
        if(msg.value < i_raffleFee){
            revert Raffle__NotEnoughETH();
        }

        //check if raffle is open
        if(s_raffleState!=RaffleState.OPEN){
            revert Raffle__NotOPEN();
        }
        //make the address payable and push as the winner will recieve money
        s_players.push(payable(msg.sender));
        //emit the event cause the storage got updated
        emit RaffleEntered(msg.sender);

    }

    //When should the winner be picked
    /*
     this func will be called by the chainlink nodes to see if the lottery is ready to have a a winner picked
     the following should be true in order for upkeepNeeded==true
     1. the time intervel has passed 
     2. the lottery is open
     3. the contract has ETH
     4. there are players
     4. subscription has LINK
    */
    function checkUpkeep(bytes memory /* checkData */)
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        //all the conds which needs to be fullfilled
        bool timeHasPassed = ((block.timestamp- s_lastTimestamp)>=i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance >0;
        bool hasPlayers = s_players.length >0;
        //this var is already declared in the return(), AND of all the params
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        // return the boolean
        return(upkeepNeeded,"");
    }


    //decide the raffle winner, pickWinner
    function performUpkeep(bytes calldata /*performData*/) external{
        //boolean check
        (bool upkeepNeeded,) = checkUpkeep("");
        if(!upkeepNeeded){
            //custom error
            revert Raffle_UpkeepNotNeeded(address(this).balance,s_players.length,s_raffleState);
        }

        //change the raffleState
        s_raffleState = RaffleState.CALCULATING;

        //create a random num for selection of a winner
        // request from VRF
        //get from VRF - 2 step process

        //copied from
        // we are exxecuting a function from the inherited contract
        //requestRandomWords take only 1 arg that's  of type struct
        
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subID,
                requestConfirmations: REQUEST_CONF,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }


    //when the rando num is generated we recieve it from the chainlink
    //VRFConsumerBaseV2Plus is abstract , so we had to define this undefined function here and overide it as it was virtual
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override{ // same requestID generated above
        // to select a winner we are going to use modulo,as the random num will be really big
        // random =12 , players=10
        // 12%10 = 2 player_2 is winner !
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_winner = winner;
        //pay the winner the entire balance of the contract
        (bool success,) = winner.call{value:address(this).balance}("");

        //check if transfer successful
        if(!success){
            revert Raffle__TransferFailed();
        }
        //event 
        emit WinnerPicked(s_winner);

        //after the winner is selected and award rewarded open the raffle again
        s_raffleState = RaffleState.OPEN;
        //clear the players array
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp; //reset it
    }

    //getter funcs

    function getRaffleFee() external view returns(uint256){
        return i_raffleFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }
}
