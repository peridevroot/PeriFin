pragma solidity >=0.4.24;

import "../interfaces/IPynth.sol";


// https://docs.perifin.io/contracts/source/interfaces/idebtcache
interface IDebtCache {
    // Views

    function cachedDebt() external view returns (uint);

    function cachedPynthDebt(bytes32 currencyKey) external view returns (uint);

    function cacheTimestamp() external view returns (uint);

    function cacheInvalid() external view returns (bool);

    function cacheStale() external view returns (bool);

    function currentPynthDebts(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory debtValues, bool anyRateIsInvalid);

    function cachedPynthDebts(bytes32[] calldata currencyKeys) external view returns (uint[] memory debtValues);

    function currentDebt() external view returns (uint debt, bool anyRateIsInvalid);

    function cacheInfo()
        external
        view
        returns (
            uint debt,
            uint timestamp,
            bool isInvalid,
            bool isStale
        );

    // Mutative functions

    function takeDebtSnapshot() external;

    function updateCachedPynthDebts(bytes32[] calldata currencyKeys) external;
}
