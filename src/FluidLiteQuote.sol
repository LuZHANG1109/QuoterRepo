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
    uint256 internal constant BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_CONTRACT_ADDRESS = 63;

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
    /// Constant variables
    uint256 internal constant X19 = 0x7ffff;

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
    function getShiftStatusById(bytes8 dexId_) public view returns (uint256 dexVariables_,uint256 rangeShift_, uint256 thresholdShift_, uint256 centerPriceShift_) {
        dexVariables_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_DEX_VARIABLES_SLOT, dexId_);
        rangeShift_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_RANGE_SHIFT_SLOT, dexId_);
        thresholdShift_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_THRESHOLD_SHIFT_SLOT, dexId_);
        centerPriceShift_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_CENTER_PRICE_SHIFT_SLOT, dexId_);
    }

    /// @notice Retrieves the shift status for a given dexKey.
    function getShiftStatusByKey(DexKey memory dexKey_) external view returns (uint256 dexVariables_,uint256 rangeShift_, uint256 thresholdShift_, uint256 centerPriceShift_) {
        bytes8 dexId_ = calculateDexIdByKey(dexKey_);
        (dexVariables_, rangeShift_, thresholdShift_, centerPriceShift_) = getShiftStatusById(dexId_);
    }

    /// @notice Retrieves the center price for a given dexId.
    function getCenterPriceById(bytes8 dexId_) external view returns (uint256 centerPrice_) {
        uint256 dexVariables_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_DEX_VARIABLES_SLOT, dexId_);
        DexKey memory dexKey_ = getDexKey(dexId_);
        centerPrice_ = ICenterPrice(AddressCalcs.addressCalc(DEPLOYER_CONTRACT, ((dexVariables_ >> DexLiteSlotsLink.BITS_DEX_LITE_DEX_VARIABLES_CENTER_PRICE_CONTRACT_ADDRESS) & X19))).centerPrice(dexKey_.token0, dexKey_.token1);
    }

    /// @notice Retrieves the center price for a given dexKey.
    function getCenterPriceByKey(DexKey memory dexKey_) external view returns (uint256 centerPrice_) {
        uint256 dexVariables_ = _readMappingStorage(DexLiteSlotsLink.DEX_LITE_DEX_VARIABLES_SLOT, calculateDexIdByKey(dexKey_));
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
}