// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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

interface IFluidDexT1 {
    struct Implementations {
        address shift;
        address admin;
        address colOperations;
        address debtOperations;
        address perfectOperationsAndOracle;
    }

    struct ConstantViews {
        uint256 dexId;
        address liquidity;
        address factory;
        Implementations implementations;
        address deployerContract;
        address token0;
        address token1;
        bytes32 supplyToken0Slot;
        bytes32 borrowToken0Slot;
        bytes32 supplyToken1Slot;
        bytes32 borrowToken1Slot;
        bytes32 exchangePriceToken0Slot;
        bytes32 exchangePriceToken1Slot;
        uint256 oracleMapping;
    }

    function constantsView() external view returns (ConstantViews memory constantsView_);
}

interface ICenterPrice {
    /// @notice Retrieves the center price for the pool
    /// @dev This function is marked as non-constant (potentially state-changing) to allow flexibility in price fetching mechanisms.
    ///      While typically used as a read-only operation, this design permits write operations if needed for certain token pairs
    ///      (e.g., fetching up-to-date exchange rates that may require state changes).
    /// @return price The current price ratio of token1 to token0, expressed with 27 decimal places
    function centerPrice() external view returns (uint price);
}

interface IShifting {
    function readFromStorage(bytes32 slot_) external view returns (uint256 result_);
}

contract FluidQuote {

    /*//////////////////////////////////////////////////////////////
                          CONSTANTS / IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    uint256 internal constant X30 = 0x3fffffff;

    /// @dev storage slot for range shift
    uint256 internal constant DEX_RANGE_SHIFT_SLOT = 7;
    /// @dev storage slot for threshold shift
    uint256 internal constant DEX_THRESHOLD_SHIFT_SLOT = 8;
    /// @dev storage slot for center price shift
    uint256 internal constant DEX_CENTER_PRICE_SHIFT_SLOT = 9;


    /*//////////////////////////////////////////////////////////////
                    External Functions
    //////////////////////////////////////////////////////////////*/
    /// @notice Retrieves the center price of the pool.
    function getCenterPrice(
        address pool_,
        uint256 dexVariables2_
    ) public view returns (uint256 centerPrice_) {
        // Get deployerContract and shift address
        IFluidDexT1.ConstantViews memory constantsView_ = IFluidDexT1(pool_).constantsView();
        address deployerContract_ = constantsView_.deployerContract;

        // centerPrice_ => center price hook
        centerPrice_ = (dexVariables2_ >> 112) & X30;

        // center price should be fetched from external source. For exmaple, in case of wstETH <> ETH pool,
        // we would want the center price to be pegged to wstETH exchange rate into ETH
        centerPrice_ = ICenterPrice(AddressCalcs.addressCalc(deployerContract_, centerPrice_)).centerPrice();
    }

    /// @notice Retrieves the shift status of the pool.
    function getShiftStatus(
        address pool_
    ) public view returns (
        uint256 _rangeShift,
        uint256 _thresholdShift,
        uint256 _centerPriceShift
    ) {
        IFluidDexT1.ConstantViews memory constantsView_ = IFluidDexT1(pool_).constantsView();
        address shift_ = constantsView_.implementations.shift;

        // read storage of variables.sol: https://etherscan.io/address/0x5B6B500981d7Faa8c83Be20514EA8067fbd42304#code#F7#L1
        _rangeShift = IShifting(shift_).readFromStorage(bytes32(DEX_RANGE_SHIFT_SLOT));
        _thresholdShift = IShifting(shift_).readFromStorage(bytes32(DEX_THRESHOLD_SHIFT_SLOT));
        _centerPriceShift = IShifting(shift_).readFromStorage(bytes32(DEX_CENTER_PRICE_SHIFT_SLOT));
    }
}