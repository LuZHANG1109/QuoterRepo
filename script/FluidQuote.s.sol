pragma solidity 0.8.21;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import {FluidQuote} from "../src/FluidQuote.sol";

contract Deploy is Test {
    FluidQuote quoter;
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

    function run() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        vm.startBroadcast(deployer);
        require(block.chainid == 1, "must be right chain");
        quoter = new FluidQuote();
        console2.log("query address", address(quoter));
        vm.stopBroadcast();
    }
}