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

        console2.log("\n  --------------- Test getDexIdByKey ---------------");
        bytes8 dexId0 = quote.calculateDexIdByKey(dexKeys[0]);
        console2.log("dexId0:");
        console2.logBytes8(dexId0);

        console2.log("\n  --------------- Test getDexKey ---------------");
        FluidLiteQuote.DexKey memory dexKey0 = quote.getDexKey(dexId0);
        console2.log("dexKey0.token0:", dexKey0.token0);
        console2.log("dexKey0.token1:", dexKey0.token1);
        console2.log("dexKey0.salt:");
        console2.logBytes32(dexKey0.salt);

        console2.log("\n  --------------- Test getLiquidityByKey ---------------");
        (uint256 centerPrice, uint256 token0ImaginaryReserves, uint256 token1ImaginaryReserves) = quote.getLiquidityByKey(dexKeys[0]);
        console2.log("centerPrice:", centerPrice);
        console2.log("token0ImaginaryReserves:", token0ImaginaryReserves);
        console2.log("token1ImaginaryReserves:", token1ImaginaryReserves);

        console2.log("\n  --------------- Test getKeyAndLiquidityById ---------------");
        (FluidLiteQuote.DexKey memory dexKey1, uint256 centerPrice1, uint256 token0ImaginaryReserves1, uint256 token1ImaginaryReserves1) = quote.getKeyAndLiquidityById(dexId0);
        console2.log("dexKey1.token0:", dexKey1.token0);
        console2.log("dexKey1.token1:", dexKey1.token1);
        console2.log("dexKey1.salt:");
        console2.logBytes32(dexKey1.salt);
        console2.log("centerPrice1:", centerPrice1);
        console2.log("token0ImaginaryReserves1:", token0ImaginaryReserves1);
        console2.log("token1ImaginaryReserves1:", token1ImaginaryReserves1);
    }
}
