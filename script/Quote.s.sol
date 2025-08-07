pragma solidity 0.8.17;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "../src/Quote.sol";

contract Deploy is Test {
    QueryData quoter;
    address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    // base
    // address stateView = 0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71;
    // address positionManager = 0x7C5f5A4bBd8fD63184577525326123B519429bDc;
    // eth
    // address stateView = 0x7fFE42C4a5DEeA5b0feC41C94C136Cf115597227;
    // address positionManager = 0xbD216513d74C8cf14cf4747E6AaA6420FF64ee9e;
    // Arbitrum
    // address stateView = 0x76Fd297e2D437cd7f76d50F01AfE6160f86e9990;
    // address positionManager = 0xd88F38F930b7952f2DB2432Cb002E7abbF3dD869;
    // Optimism
    // address stateView = 0xc18a3169788F4F75A170290584ECA6395C75Ecdb;
    // address positionManager = 0x3C3Ea4B57a46241e54610e5f022E5c45859A1017;
    // Polygon
    // address stateView = 0x5eA1bD7974c8A611cBAB0bDCAFcB1D9CC9b3BA5a;
    // address positionManager = 0x1Ec2eBf4F37E7363FDfe3551602425af0B3ceef9;
    // Blast
    // address stateView = 0x12a88AE16F46DCe4e8B15368008Ab3380885df30;
    // address positionManager = 0x4AD2F4CcA2682cBB5B950d660dD458a1D3f1bAaD;
    // Avalanche
    // address stateView = 0xc3c9e198C735a4b97e3e683f391cCBDD60B69286;
    // address positionManager = 0xB74b1F14d2754AcfcbBe1a221023a5cf50Ab8ACD;
    // BNB Smart Chain
    // address stateView = 0xd13Dd3D6E93f276FAfc9Db9E6BB47C1180aeE0c4;
    // address positionManager = 0x7A4a5c919aE2541AeD11041A1AEeE68f1287f95b;
    // UniChain
    address stateView = 0x86e8631A016F9068C3f085fAF484Ee3F5fDee8f2;
    address positionManager = 0x4529A01c7A0410167c5740C487A8DE60232617bf;

    function run() public {
        // base
        // vm.createSelectFork("https://base.llamarpc.com");
        // eth
        // vm.createSelectFork("https://eth.blockrazor.xyz");
        // Arbitrum 42161
        // vm.createSelectFork(vm.envString("ARB_RPC_URL"));
        // Optimism
        // vm.createSelectFork(vm.envString("OP_RPC_URL"));
        // Polygon
        // vm.createSelectFork(vm.envString("POLYGON_RPC_URL"));
        // Blast 81457
        // vm.createSelectFork(vm.envString("BLAST_RPC_URL"));
        // Avalanche
        // vm.createSelectFork(vm.envString("AVAX_RPC_URL"));
        // BNB Smart Chain
        // vm.createSelectFork("https://binance.llamarpc.com");
        // unichain
        vm.createSelectFork("https://mainnet.unichain.org");

        vm.startBroadcast(deployer);
        require(block.chainid == 130, "must be right chain");
        quoter = new QueryData(stateView, positionManager);
        console2.log("query address", address(quoter));
        vm.stopBroadcast();
    }
}