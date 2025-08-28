// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "forge-std/console2.sol";
import "forge-std/test.sol";
import {FluidLiteQuote} from "../src/FluidLiteQuote.sol";

contract FluidLiteQuoteTest is Test {
    FluidLiteQuote quote;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        quote = new FluidLiteQuote(
            0xBbcb91440523216e2b87052A99F69c604A7b6e00, // dex contract: FluidDexLite
            0x4EC7b668BAF70d4A4b0FC7941a7708A07b6d45Be // deploy contract: FluidContractFactory
        );
    }

    function test_fluidLiteQuote() public {
        console2.log("--------------- Test getAllDexKeys ---------------");
        (FluidLiteQuote.DexKey[] memory dexKeys, bytes8[] memory dexIds) = quote.getAllDexKeys();
        console2.log("dexKeys.length:", dexKeys.length);

        console2.log("dexKeys[0].token0:", dexKeys[0].token0);
        console2.log("dexKeys[0].token1:", dexKeys[0].token1);
        console2.log("dexKeys[0].salt:");
        console2.logBytes32(dexKeys[0].salt);
        console2.log("dexIds[0]:");
        console2.logBytes8(dexIds[0]);

        console2.log("\n  --------------- Test calculateDexIdByKey ---------------");
        bytes8 dexId0 = quote.calculateDexIdByKey(dexKeys[0]);
        console2.log("dexId0:");
        console2.logBytes8(dexId0);

        console2.log("\n  --------------- Test getDexKey ---------------");
        FluidLiteQuote.DexKey memory dexKey0 = quote.getDexKey(dexId0);
        console2.log("dexKey0.token0:", dexKey0.token0);
        console2.log("dexKey0.token1:", dexKey0.token1);
        console2.log("dexKey0.salt:");
        console2.logBytes32(dexKey0.salt);

        // console2.log("\n  --------------- Test getCenterPriceById ---------------");
        // uint256 centerPrice = quote.getCenterPriceById(dexId0);
        // console2.log("centerPrice:", centerPrice);

        console2.log("\n  --------------- Test getShiftStatusById ---------------");
        for (uint256 i = 0; i < dexIds.length; i++) {
            console2.log("----- dexId index:", i, " -----");
            (uint256 dexVariables, uint256 rangeShift, uint256 thresholdShift, uint256 centerPriceShift, uint256 token0ImaginaryReserves, uint256 token1ImaginaryReserves) = quote.getShiftStatusById(dexIds[i]);
            console2.log("dexVariables:", dexVariables);
            console2.log("rangeShift:", rangeShift);
            console2.log("thresholdShift:", thresholdShift);
            console2.log("centerPriceShift:", centerPriceShift);
            uint256 token0AdjustedSupply_ = (dexVariables >> 136) & 0xfffffffffffffff;
            uint256 token1AdjustedSupply_ = (dexVariables >> 196) & 0xfffffffffffffff;
            console2.log("token0AdjustedSupply_:", token0AdjustedSupply_);
            console2.log("token1AdjustedSupply_:", token1AdjustedSupply_);
            console2.log("token0ImaginaryReserves_:", token0ImaginaryReserves);
            console2.log("token1ImaginaryReserves_:", token1ImaginaryReserves);
        }
    }
}
