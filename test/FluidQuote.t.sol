// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import {FluidQuote} from "../src/FluidQuote.sol";

contract FluidQuoteTest is Test {
    FluidQuote quote;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        quote = new FluidQuote();
    }

    function test_fluidQuote() public {
        console2.log("--------------- Test getCenterPrice ---------------");
        uint256 centerPrice = quote.getCenterPrice(
            0x0B1a513ee24972DAEf112bC777a5610d4325C9e7, // pool
            420036352368278820019270786931024958529469536632329727776002585951495258695 // dexVariables2_
        );
        console2.log("centerPrice:", centerPrice);

        console2.log("--------------- Test getShiftStatus ---------------");
        (uint256 _rangeShift, uint256 _thresholdShift, uint256 _centerPriceShift) = quote.getShiftStatus(
            0x0B1a513ee24972DAEf112bC777a5610d4325C9e7
        );
        console2.log("rangeShift:", _rangeShift);
        console2.log("thresholdShift:", _thresholdShift);
        console2.log("centerPriceShift:", _centerPriceShift);
    }
}
