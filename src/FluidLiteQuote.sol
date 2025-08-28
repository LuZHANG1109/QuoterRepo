// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/// Copy from https://etherscan.io/address/0xBbcb91440523216e2b87052A99F69c604A7b6e00#code
/// @notice library that helps in reading / working with storage slot data of Fluid Dex Lite.
library DexLiteSlotsLink {
    /// @dev storage slot for dexes list
    uint256 internal constant DEX_LITE_DEXES_LIST_SLOT = 1;
    /// @dev storage slot for is dex variables
    uint256 internal constant DEX_LITE_DEX_VARIABLES_SLOT = 2;
    /// @dev storage slot for center price shift
    uint256 internal constant DEX_LITE_CENTER_PRICE_SHIFT_SLOT = 3;
    /// @dev storage slot for range shift
    uint256 internal constant DEX_LITE_RANGE_SHIFT_SLOT = 4;
    /// @dev storage slot for threshold shift
    uint256 internal constant DEX_LITE_THRESHOLD_SHIFT_SLOT = 5;

    // DexVariables
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_REBALANCING_STATUS = 20;
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_SHIFT_ACTIVE = 22;
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE = 23;
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_CONTRACT_ADDRESS = 63;
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_RANGE_PERCENT_SHIFT_ACTIVE = 82;
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_UPPER_PERCENT = 83;
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_LOWER_PERCENT = 97;
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_TOKEN_0_TOTAL_SUPPLY_ADJUSTED = 136;
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_TOKEN_1_TOTAL_SUPPLY_ADJUSTED = 196;

    // CenterPriceShift
    uint256 internal constant BITS_DEX_LITE_CENTER_PRICE_SHIFT_LAST_INTERACTION_TIMESTAMP = 0;
    uint256 internal constant BITS_DEX_LITE_CENTER_PRICE_SHIFT_SHIFTING_TIME = 33;
    uint256 internal constant BITS_DEX_LITE_CENTER_PRICE_SHIFT_MAX_CENTER_PRICE = 57;
    uint256 internal constant BITS_DEX_LITE_CENTER_PRICE_SHIFT_MIN_CENTER_PRICE = 85;
    uint256 internal constant BITS_DEX_LITE_CENTER_PRICE_SHIFT_PERCENT = 113;
    uint256 internal constant BITS_DEX_LITE_CENTER_PRICE_SHIFT_TIME_TO_SHIFT = 133;
    uint256 internal constant BITS_DEX_LITE_CENTER_PRICE_SHIFT_TIMESTAMP = 153;

    // RangeShift
    uint256 internal constant BITS_DEX_LITE_RANGE_SHIFT_OLD_UPPER_RANGE_PERCENT = 0;
    uint256 internal constant BITS_DEX_LITE_RANGE_SHIFT_OLD_LOWER_RANGE_PERCENT = 14;
    uint256 internal constant BITS_DEX_LITE_RANGE_SHIFT_TIME_TO_SHIFT = 28;
    uint256 internal constant BITS_DEX_LITE_RANGE_SHIFT_TIMESTAMP = 48;

    /// @notice Calculating the slot ID for Dex contract for single mapping at `slot_` for `key_`
    function calculateMappingStorageSlot(uint256 slot_, bytes32 key_) internal pure returns (bytes32) {
        return keccak256(abi.encode(key_, slot_));
    }
}

/// @notice implements calculation of address for contracts deployed through CREATE.
/// Accepts contract deployed from which address & nonce
library AddressCalcs {

    /// @notice                         Computes the address of a contract based
    /// @param deployedFrom_            Address from which the contract was deployed
    /// @param nonce_                   Nonce at which the contract was deployed
    /// @return contract_               Address of deployed contract
    function addressCalc(address deployedFrom_, uint nonce_) internal pure returns (address contract_) {
        // @dev based on https://ethereum.stackexchange.com/a/61413

        // nonce of smart contract always starts with 1. so, with nonce 0 there won't be any deployment
        // hence, nonce of vault deployment starts with 1.
        bytes memory data;
        if (nonce_ == 0x00) {
            return address(0);
        } else if (nonce_ <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployedFrom_, uint8(nonce_));
        } else if (nonce_ <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployedFrom_, bytes1(0x81), uint8(nonce_));
        } else if (nonce_ <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployedFrom_, bytes1(0x82), uint16(nonce_));
        } else if (nonce_ <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployedFrom_, bytes1(0x83), uint24(nonce_));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), deployedFrom_, bytes1(0x84), uint32(nonce_));
        }

        return address(uint160(uint256(keccak256(data))));
    }

}

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

interface IFluidDexLite {
    function readFromStorage(bytes32 slot_) external view returns (uint256 result_);
}

interface ICenterPrice {
    /// @notice Retrieves the center price for the pool. The `view` modifier is added to support view functions.
    ///         Notice that
    /// @dev This function is marked as non-constant (potentially state-changing) to allow flexibility in price fetching mechanisms.
    ///      While typically used as a read-only operation, this design permits write operations if needed for certain token pairs
    ///      (e.g., fetching up-to-date exchange rates that may require state changes).
    /// @return price The current price of token0 in terms of token1, expressed with 27 decimal places
    function centerPrice(address token0_, address token1_) external view returns (uint256);
}

contract FluidLiteQuote {
    // Copy from ConstantVariables of https://etherscan.io/address/0xBbcb91440523216e2b87052A99F69c604A7b6e00#code
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS / IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant DEFAULT_EXPONENT_SIZE = 8;
    uint256 internal constant DEFAULT_EXPONENT_MASK = 0xFF;

    uint256 internal constant X1 = 0x1;
    uint256 internal constant X2 = 0x3;
    uint256 internal constant X14 = 0x3fff;
    uint256 internal constant X19 = 0x7ffff;
    uint256 internal constant X20 = 0xfffff;
    uint256 internal constant X24 = 0xffffff;
    uint256 internal constant X28 = 0xfffffff;
    uint256 internal constant X33 = 0x1ffffffff;
    uint256 internal constant X40 = 0xffffffffff;
    uint256 internal constant X60 = 0xfffffffffffffff;
    uint256 internal constant X73 = 0x1ffffffffffffffffff;

    uint256 internal constant FOUR_DECIMALS = 1e4;
    uint256 internal constant SIX_DECIMALS = 1e6;

    uint256 internal constant PRICE_PRECISION = 1e27;

    /// Immutable variables
    address public immutable DEX;
    address public immutable DEPLOYER_CONTRACT;

    struct DexKey {
        address token0;
        address token1;
        bytes32 salt;
    }

    constructor(address dex_, address deployerContract_) {
        DEX = dex_;
        DEPLOYER_CONTRACT = deployerContract_;
    }

    /*//////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/
    /// @notice Calculates the dexId for a given dexKey.
    function calculateDexIdByKey(DexKey memory dexKey_) public pure returns (bytes8 dexId_) {
        return bytes8(keccak256(abi.encode(dexKey_)));
    }

    /// @notice Retrieves all dexKeys and dexIds from the dexes list.
    function getAllDexKeys() external view returns (DexKey[] memory dexKeys_, bytes8[] memory dexIds_) {
        uint256 length_ = _readStorage(DexLiteSlotsLink.DEX_LITE_DEXES_LIST_SLOT);
        bytes32 dataSlot_ = keccak256(abi.encode(DexLiteSlotsLink.DEX_LITE_DEXES_LIST_SLOT));

        dexKeys_ = new DexKey[](length_);
        dexIds_ = new bytes8[](length_);
        for (uint256 i = 0; i < length_; i++) {
            uint256 offset_ = i * 3;
            dexKeys_[i].token0 = address(uint160(_readStorage(uint256(dataSlot_) + offset_)));
            dexKeys_[i].token1 = address(uint160(_readStorage(uint256(dataSlot_) + offset_ + 1)));
            dexKeys_[i].salt = bytes32(_readStorage(uint256(dataSlot_) + offset_ + 2));
            dexIds_[i] = calculateDexIdByKey(dexKeys_[i]);
        }
    }

    /// @notice Retrieves the dexKey for a given dexId.
    function getDexKey(bytes8 dexId_) public view returns (DexKey memory dexKey_) {
        uint256 length_ = _readStorage(DexLiteSlotsLink.DEX_LITE_DEXES_LIST_SLOT);
        bytes32 dataSlot_ = keccak256(abi.encode(DexLiteSlotsLink.DEX_LITE_DEXES_LIST_SLOT));

        for (uint256 i = 0; i < length_; i++) {
            uint256 offset_ = i * 3;
            address token0_ = address(uint160(_readStorage(uint256(dataSlot_) + offset_)));
            address token1_ = address(uint160(_readStorage(uint256(dataSlot_) + offset_ + 1)));
            bytes32 salt_ = bytes32(_readStorage(uint256(dataSlot_) + offset_ + 2));

            if (bytes8(keccak256(abi.encode(DexKey(token0_, token1_, salt_)))) == dexId_) {
                return DexKey(token0_, token1_, salt_);
            }
        }
        revert("DexKey not found");
    }

    /// @notice Retrieves the shift status for a given dexId.
    function getShiftStatusById(bytes8 dexId_) public view returns (uint256 dexVariables_,uint256 rangeShift_, uint256 thresholdShift_, uint256 centerPriceShift_, uint256 token0ImaginaryReserves_, uint256 token1ImaginaryReserves_) {
        dexVariables_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_DEX_VARIABLES_SLOT, dexId_);
        rangeShift_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_RANGE_SHIFT_SLOT, dexId_);
        thresholdShift_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_THRESHOLD_SHIFT_SLOT, dexId_);
        centerPriceShift_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_CENTER_PRICE_SHIFT_SLOT, dexId_);

        DexKey memory dexKey_ = getDexKey(dexId_);
        uint256 token0AdjustedSupply_ = (dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_TOKEN_0_TOTAL_SUPPLY_ADJUSTED) & X60;
        uint256 token1AdjustedSupply_ = (dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_TOKEN_1_TOTAL_SUPPLY_ADJUSTED) & X60;
        (, token0ImaginaryReserves_, token1ImaginaryReserves_) =
            _getPricesAndReserves(dexKey_, dexVariables_, dexId_, token0AdjustedSupply_, token1AdjustedSupply_);
    }

    /// @notice Retrieves the center price for a given dexId.
    function getCenterPriceById(bytes8 dexId_) external view returns (uint256 centerPrice_) {
        uint256 dexVariables_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_DEX_VARIABLES_SLOT, dexId_);
        DexKey memory dexKey_ = getDexKey(dexId_);
        centerPrice_ = ICenterPrice(AddressCalcs.addressCalc(DEPLOYER_CONTRACT, ((dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_CONTRACT_ADDRESS) & X19))).centerPrice(dexKey_.token0, dexKey_.token1);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/
    function _readStorage(uint256 slot_) internal view returns (uint256 value_) {
        value_ = IFluidDexLite(DEX).readFromStorage(bytes32(slot_));
    }
    
    function _readMappingStorage(uint256 baseSlot_, bytes8 key_) internal view returns (uint256 value_) {
        bytes32 slot_ = DexLiteSlotsLink.calculateMappingStorageSlot(baseSlot_, key_);
        value_ = IFluidDexLite(DEX).readFromStorage(slot_);
    }

    /// @notice Calculates and returns the current prices and exchange prices for the pool
    /// Copy from helpers.sol of https://etherscan.io/address/0xBbcb91440523216e2b87052A99F69c604A7b6e00#code.
    /// @param dexVariables_ The first set of DEX variables containing various pool parameters
    function _getPricesAndReserves(
        DexKey memory dexKey_,
        uint256 dexVariables_,
        bytes8 dexId_,
        uint256 token0Supply_,
        uint256 token1Supply_
    ) internal view returns (uint256 centerPrice_, uint256 token0ImaginaryReserves_, uint256 token1ImaginaryReserves_) {
        uint256 centerPriceShift1_;
        // Fetch center price
        if (((dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_SHIFT_ACTIVE) & X1) == 0) {
            // centerPrice_ => center price nonce
            centerPrice_ = (dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_CONTRACT_ADDRESS) & X19;
            if (centerPrice_ == 0) {
                centerPrice_ = (dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE) & X40;
                centerPrice_ = (centerPrice_ >> DEFAULT_EXPONENT_SIZE) << (centerPrice_ & DEFAULT_EXPONENT_MASK);
            } else {
                // center price should be fetched from external source. For exmaple, in case of wstETH <> ETH pool,
                // we would want the center price to be pegged to wstETH exchange rate into ETH
                centerPrice_ = 
                    ICenterPrice(AddressCalcs.addressCalc(DEPLOYER_CONTRACT, centerPrice_)).centerPrice(dexKey_.token0, dexKey_.token1);
            }
        } else {
            // an active centerPrice_ shift is going on
            (centerPrice_, centerPriceShift1_) = _calcCenterPrice(dexKey_, dexVariables_, dexId_);
        }

        uint256 upperRangePercent_ = (dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_UPPER_PERCENT) & X14;
        uint256 lowerRangePercent_ = (dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_LOWER_PERCENT) & X14;
        if (((dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_RANGE_PERCENT_SHIFT_ACTIVE) & X1) == 1) {
            // an active range shift is going on
            (upperRangePercent_, lowerRangePercent_) = _calcRangeShifting(upperRangePercent_, lowerRangePercent_, dexId_);
        }

        uint256 upperRangePrice_;
        uint256 lowerRangePrice_;
        unchecked {
            // 1% = 1e2, 100% = 1e4
            upperRangePrice_ = (centerPrice_ * FOUR_DECIMALS) / (FOUR_DECIMALS - upperRangePercent_);
            // 1% = 1e2, 100% = 1e4
            lowerRangePrice_ = (centerPrice_ * (FOUR_DECIMALS - lowerRangePercent_)) / FOUR_DECIMALS;
        }

        // Rebalance center price if rebalancing is on
        // temp_ => rebalancingStatus_
        uint256 temp_ = (dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_REBALANCING_STATUS) & X2;
        uint256 temp2_;
        if (temp_ > 1) {
            unchecked {
                // temp2_ => centerPriceShift_
                if (temp_ == 2) {
                    // temp2_ = _centerPriceShift[dexId_];
                    temp2_ = centerPriceShift1_; // may should be the storage value of _centerPriceShift[dexId_], so here use the return value of _calcCenterPrice
                    uint256 shiftingTime_ = (temp2_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_SHIFTING_TIME) & X24;
                    uint256 timeElapsed_ = block.timestamp - ((temp2_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_LAST_INTERACTION_TIMESTAMP) & X33);
                    // price shifting towards upper range
                    if (timeElapsed_ < shiftingTime_) {
                        centerPrice_ = centerPrice_ + (((upperRangePrice_ - centerPrice_) * timeElapsed_) / shiftingTime_);
                    } else {
                        // 100% price shifted
                        centerPrice_ = upperRangePrice_;
                    }
                } else if (temp_ == 3) {
                    // temp2_ = _centerPriceShift[dexId_];
                    temp2_ = centerPriceShift1_; // may should be the storage value of _centerPriceShift[dexId_], so here use the return value of _calcCenterPrice
                    uint256 shiftingTime_ = (temp2_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_SHIFTING_TIME) & X24;
                    uint256 timeElapsed_ = block.timestamp - ((temp2_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_LAST_INTERACTION_TIMESTAMP) & X33);
                    // price shifting towards lower range
                    if (timeElapsed_ < shiftingTime_) {
                        centerPrice_ = centerPrice_ - (((centerPrice_ - lowerRangePrice_) * timeElapsed_) / shiftingTime_);
                    } else {
                        // 100% price shifted
                        centerPrice_ = lowerRangePrice_;
                    }
                }

                // If rebalancing actually happened then make sure price is within min and max bounds, and update range prices
                if (temp2_ > 0) {
                    // Make sure center price is within min and max bounds
                    // temp_ => max center price
                    temp_ = (temp2_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_MAX_CENTER_PRICE) & X28;
                    temp_ = (temp_ >> DEFAULT_EXPONENT_SIZE) << (temp_ & DEFAULT_EXPONENT_MASK);
                    if (centerPrice_ > temp_) {
                        // if center price is greater than max center price
                        centerPrice_ = temp_;
                    } else {
                        // check if center price is less than min center price
                        // temp_ => min center price
                        temp_ = (temp2_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_MIN_CENTER_PRICE) & X28;
                        temp_ = (temp_ >> DEFAULT_EXPONENT_SIZE) << (temp_ & DEFAULT_EXPONENT_MASK);
                        if (centerPrice_ < temp_) centerPrice_ = temp_;
                    }

                    // Update range prices as center price moved
                    upperRangePrice_ = (centerPrice_ * FOUR_DECIMALS) / (FOUR_DECIMALS - upperRangePercent_);
                    lowerRangePrice_ = (centerPrice_ * (FOUR_DECIMALS - lowerRangePercent_)) / FOUR_DECIMALS;
                }
            }  
        }

        // temp_ => geometricMeanPrice_
        unchecked {         
            if (upperRangePrice_ < 1e38) {
                // 1e38 * 1e38 = 1e76 which is less than max uint limit
                temp_ = FixedPointMathLib.sqrt(upperRangePrice_ * lowerRangePrice_);
            } else {
                // upperRange_ price is pretty large hence lowerRange_ will also be pretty large
                temp_ = FixedPointMathLib.sqrt((upperRangePrice_ / 1e18) * (lowerRangePrice_ / 1e18)) * 1e18;
            }
        }

        if (temp_ < 1e27) {
            (token0ImaginaryReserves_, token1ImaginaryReserves_) = 
                _calculateReservesOutsideRange(temp_, upperRangePrice_, token0Supply_, token1Supply_);
        } else {
            // inversing, something like `xy = k` so for calculation we are making everything related to x into y & y into x
            // 1 / geometricMean for new geometricMean
            // 1 / lowerRange will become upper range
            // 1 / upperRange will become lower range
            unchecked {
                (token1ImaginaryReserves_, token0ImaginaryReserves_) = _calculateReservesOutsideRange(
                    (1e54 / temp_),
                    (1e54 / lowerRangePrice_),
                    token1Supply_,
                    token0Supply_
                );
            }
        }

        unchecked {
            token0ImaginaryReserves_ += token0Supply_;
            token1ImaginaryReserves_ += token1Supply_;
        }
    }

    /// @dev Calculates the new center price during an active price shift
    /// @param dexVariables_ The current state of dex variables
    /// @return newCenterPrice_ The updated center price
    /// @notice This function gradually shifts the center price towards a new target price over time
    /// @notice It uses an external price source (via ICenterPrice) to determine the target price
    /// @notice The shift continues until the current price reaches the target, or the shift duration ends
    /// @notice Once the shift is complete, it updates the state and clears the shift data
    /// @notice The shift rate is dynamic and depends on:
    /// @notice - Time remaining in the shift duration
    /// @notice - The new center price (fetched externally, which may change)
    /// @notice - The current (old) center price
    /// @notice This results in a fuzzy shifting mechanism where the rate can change as these parameters evolve
    /// @notice The externally fetched new center price is expected to not differ significantly from the last externally fetched center price
    function _calcCenterPrice(
        DexKey memory dexKey_,
        uint256 dexVariables_,
        bytes8 dexId_
    ) internal view returns (uint256 newCenterPrice_, uint256 centerPriceShift1_) {
        uint256 oldCenterPrice_ = (dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE) & X40;
        oldCenterPrice_ = (oldCenterPrice_ >> DEFAULT_EXPONENT_SIZE) << (oldCenterPrice_ & DEFAULT_EXPONENT_MASK);
        uint256 centerPriceShift_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_CENTER_PRICE_SHIFT_SLOT, dexId_);
        uint256 startTimeStamp_ = (centerPriceShift_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_TIMESTAMP) & X33;

        uint256 fromTimeStamp_ = (centerPriceShift_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_LAST_INTERACTION_TIMESTAMP) & X33;
        fromTimeStamp_ = fromTimeStamp_ > startTimeStamp_ ? fromTimeStamp_ : startTimeStamp_;

        newCenterPrice_ = ICenterPrice(
            AddressCalcs.addressCalc(DEPLOYER_CONTRACT, ((dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_CONTRACT_ADDRESS) & X19)))
            .centerPrice(dexKey_.token0, dexKey_.token1);
        
        unchecked {
            uint256 priceShift_ = (oldCenterPrice_ * ((centerPriceShift_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_PERCENT) & X20) * (block.timestamp - fromTimeStamp_)) 
                                    / (((centerPriceShift_ >> DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_TIME_TO_SHIFT) & X20) * SIX_DECIMALS);

            centerPriceShift1_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_CENTER_PRICE_SHIFT_SLOT, dexId_);

            if (newCenterPrice_ > oldCenterPrice_) {
                // shift on positive side
                oldCenterPrice_ += priceShift_;
                if (newCenterPrice_ > oldCenterPrice_) {
                    newCenterPrice_ = oldCenterPrice_;
                } else {
                    // shifting fully done
                    // _centerPriceShift[dexId_] = _centerPriceShift[dexId_] & ~(X73 << DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_PERCENT);
                    centerPriceShift1_ = centerPriceShift1_ & ~(X73 << DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_PERCENT);
                    // making active shift as 0 because shift is over
                    // fetching from storage and storing in storage, aside from admin module dexVariables2 only updates these shift function.
                    // _dexVariables[dexId_] = _dexVariables[dexId_] & ~uint256(1 << DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_SHIFT_ACTIVE); // modified but not used after here
                }
            } else {
                oldCenterPrice_ = oldCenterPrice_ > priceShift_ ? oldCenterPrice_ - priceShift_ : 0;
                // In case of oldCenterPrice_ ending up 0, which could happen when a lot of time has passed (pool has no swaps for many days or weeks)
                // then below we get into the else logic which will fully conclude shifting and return newCenterPrice_
                // as it was fetched from the external center price source.
                // not ideal that this would ever happen unless the pool is not in use and all/most users have left leaving not enough liquidity to trade on
                if (newCenterPrice_ < oldCenterPrice_) {
                    newCenterPrice_ = oldCenterPrice_;
                } else {
                    // shifting fully done
                    // _centerPriceShift[dexId_] = _centerPriceShift[dexId_] & ~(X73 << DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_PERCENT);
                    centerPriceShift1_ = centerPriceShift1_ & ~(X73 << DexLiteSlotsLink.BITS_DEX_LITE_CENTER_PRICE_SHIFT_PERCENT);
                    // making active shift as 0 because shift is over
                    // fetching from storage and storing in storage, aside from admin module dexVariables2 only updates these shift function.
                    // _dexVariables[dexId_] = _dexVariables[dexId_] & ~uint256(1 << DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_SHIFT_ACTIVE); // modified but not used after here
                }
            }
        }
    }

    /// @dev Calculates the new upper and lower range values during an active range shift
    /// @param upperRange_ The target upper range value
    /// @param lowerRange_ The target lower range value
    /// @notice This function handles the gradual shifting of range values over time
    /// @notice If the shift is complete, it updates the state and clears the shift data
    function _calcRangeShifting(
        uint256 upperRange_,
        uint256 lowerRange_,
        bytes8 dexId_
    ) internal view returns (uint256, uint256) {
        // uint256 rangeShift_ = _rangeShift[dexId_];
        uint256 rangeShift_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_RANGE_SHIFT_SLOT, dexId_);
        uint256 shiftDuration_ = (rangeShift_ >> DexLiteSlotsLink.BITS_DEX_LITE_RANGE_SHIFT_TIME_TO_SHIFT) & X20;
        uint256 startTimeStamp_ = (rangeShift_ >> DexLiteSlotsLink.BITS_DEX_LITE_RANGE_SHIFT_TIMESTAMP) & X33;

        uint256 timePassed_;
        unchecked {
            if ((startTimeStamp_ + shiftDuration_) < block.timestamp) {
                // shifting fully done
                // delete _rangeShift[dexId_];
                // making active shift as 0 because shift is over
                // fetching from storage and storing in storage, aside from admin module dexVariables only updates from this function and _calcThresholdShifting.
                // _dexVariables[dexId_] = _dexVariables[dexId_] & ~uint256(1 << DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_RANGE_PERCENT_SHIFT_ACTIVE); // modified but not used after here
                return (upperRange_, lowerRange_);
            }
            timePassed_ = block.timestamp - startTimeStamp_;
        }
        return (
            _calcShiftingDone(upperRange_, (rangeShift_ >> DexLiteSlotsLink.BITS_DEX_LITE_RANGE_SHIFT_OLD_UPPER_RANGE_PERCENT) & X14, timePassed_, shiftDuration_),
            _calcShiftingDone(lowerRange_, (rangeShift_ >> DexLiteSlotsLink.BITS_DEX_LITE_RANGE_SHIFT_OLD_LOWER_RANGE_PERCENT) & X14, timePassed_, shiftDuration_)
        );
    }

    /// @dev This function calculates the new value of a parameter after a shifting process
    /// @param current_ The current value is the final value where the shift ends
    /// @param old_ The old value from where shifting started
    /// @param timePassed_ The time passed since shifting started
    /// @param shiftDuration_ The total duration of the shift when old_ reaches current_
    /// @return The new value of the parameter after the shift
    function _calcShiftingDone(uint256 current_, uint256 old_, uint256 timePassed_, uint256 shiftDuration_) internal pure returns (uint256) {
        unchecked {
            if (current_ > old_) {
                return (old_ + (((current_ - old_) * timePassed_) / shiftDuration_));
            } else {
                return (old_ - (((old_ - current_) * timePassed_) / shiftDuration_));
            }
        }
    }

    /// @dev getting reserves outside range.
    /// @param gp_ is geometric mean pricing of upper percent & lower percent
    /// @param pa_ price of upper range or lower range
    /// @param rx_ real reserves of token0 or token1
    /// @param ry_ whatever is rx_ the other will be ry_
    function _calculateReservesOutsideRange(uint256 gp_, uint256 pa_, uint256 rx_, uint256 ry_) internal pure returns (uint256 xa_, uint256 yb_) {
        // equations we have:
        // 1. x*y = k
        // 2. xa*ya = k
        // 3. xb*yb = k
        // 4. Pa = ya / xa = upperRange_ (known)
        // 5. Pb = yb / xb = lowerRange_ (known)
        // 6. x - xa = rx = real reserve of x (known)
        // 7. y - yb = ry = real reserve of y (known)
        // With solving we get:
        // ((Pa*Pb)^(1/2) - Pa)*xa^2 + (rx * (Pa*Pb)^(1/2) + ry)*xa + rx*ry = 0
        // yb = yb = xa * (Pa * Pb)^(1/2)

        // xa = (GP⋅rx + ry + (-rx⋅ry⋅4⋅(GP - Pa) + (GP⋅rx + ry)^2)^0.5) / (2Pa - 2GP)
        // multiply entire equation by 1e27 to remove the price decimals precision of 1e27
        // xa = (GP⋅rx + ry⋅1e27 + (rx⋅ry⋅4⋅(Pa - GP)⋅1e27 + (GP⋅rx + ry⋅1e27)^2)^0.5) / 2*(Pa - GP)
        // dividing the equation with 2*(Pa - GP). Pa is always > GP so answer will be positive.
        // xa = (((GP⋅rx + ry⋅1e27) / 2*(Pa - GP)) + (((rx⋅ry⋅4⋅(Pa - GP)⋅1e27) / 4*(Pa - GP)^2) + ((GP⋅rx + ry⋅1e27) / 2*(Pa - GP))^2)^0.5)
        // xa = (((GP⋅rx + ry⋅1e27) / 2*(Pa - GP)) + (((rx⋅ry⋅1e27) / (Pa - GP)) + ((GP⋅rx + ry⋅1e27) / 2*(Pa - GP))^2)^0.5)

        // dividing in 3 parts for simplification:
        // part1 = (Pa - GP)
        // part2 = (GP⋅rx + ry⋅1e27) / (2*part1)
        // part3 = rx⋅ry
        // note: part1 will almost always be < 1e28 but in case it goes above 1e27 then it's extremely unlikely it'll go above > 1e29
        unchecked {
            uint256 p1_ = pa_ - gp_;
            uint256 p2_ = ((gp_ * rx_) + (ry_ * PRICE_PRECISION)) / (2 * p1_);

            // removed <1e50 check becuase rx_ * ry_ will never be greater than 1e50
            // Directly used p3_ below instead of using a variable for it
            // uint256 p3_ = (rx_ * ry_ * PRICE_PRECISION) / p1_;

            // xa = part2 + (part3 + (part2 * part2))^(1/2)
            // yb = xa_ * gp_
            xa_ = p2_ + FixedPointMathLib.sqrt((((rx_ * ry_ * PRICE_PRECISION) / p1_) + (p2_ * p2_)));
            yb_ = (xa_ * gp_) / PRICE_PRECISION;
        }
    }
}