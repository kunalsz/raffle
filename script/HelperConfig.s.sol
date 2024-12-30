// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

//defining chainIDs
abstract contract CodeConstants{
    //VRF mock values
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;

    //chainIDs
    uint256 public constant ETH_SEP_CHAIN_ID = 11155111;
    uint256 public constant ETH_LOCAL_CHAIN_ID = 31337;
}

// helperConfig is for the constructor to be passed in the Raffle contract
contract HelperConfig is CodeConstants,Script{

    error HelperConfig_InvalidChainID();

    struct NetworkConfig{
        uint256 raffleFee;
        uint256 interval;
        bytes32 keyHash;
        uint256 subID;
        uint32 callbackGasLimit;
        address vrfCoordinator;
    }

    //define the struct var
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    //constructor
    constructor(){
        networkConfigs[ETH_SEP_CHAIN_ID] = getSepoliaEthConfig();
    }
    
    function getConfigByChainID(uint256 chainId) public returns(NetworkConfig memory){
        if(networkConfigs[chainId].vrfCoordinator != address(0)){
            return networkConfigs[chainId];
        } else if(chainId==ETH_LOCAL_CHAIN_ID){
            return getAnvilEthConfig();
        }else{
            revert HelperConfig_InvalidChainID();
        }
    }

    function getConfig() public returns(NetworkConfig memory){
        return getConfigByChainID(block.chainid);
    }

    //for sepolia test net
    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            raffleFee:0.01 ether,
            interval:30, //30secs
            vrfCoordinator : 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit : 500000,
            subID:0
        });
    }

    function getAnvilEthConfig() public returns(NetworkConfig memory){
        //check if we have set an active network config
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }

        //create anvil mocks
        vm.startBroadcast();

        //it takes in baseFee,gasPrice and weiPerUnitLINK
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,MOCK_GAS_PRICE_LINK,MOCK_WEI_PER_UINT_LINK);

        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            raffleFee:0.01 ether,
            interval:30, //30secs
            vrfCoordinator : address(vrfCoordinatorMock),
            keyHash : 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit : 500000,
            subID:0
        });
    }
}
