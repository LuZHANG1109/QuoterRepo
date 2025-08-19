pragma solidity 0.8.29;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import {FluidLiteQuote} from "../src/FluidLiteQuote.sol";

contract Deploy is Test {
    FluidLiteQuote quoter;
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        // require(deployer == 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad, "wrong deployer! change the private key");
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        vm.startBroadcast(deployer);
        require(block.chainid == 1, "must be right chain");
        quoter = new FluidLiteQuote(
            0xBbcb91440523216e2b87052A99F69c604A7b6e00, // dex contract: FluidDexLite
            0x4EC7b668BAF70d4A4b0FC7941a7708A07b6d45Be // deploy contract: FluidContractFactory
        );
        console2.log("query address", address(quoter));
        vm.stopBroadcast();
    }
}