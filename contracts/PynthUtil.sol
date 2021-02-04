pragma solidity ^0.5.16;

// Inheritance
import "./interfaces/IPynth.sol";
import "./interfaces/IPeriFin.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IERC20.sol";


// https://docs.perifin.io/contracts/source/contracts/pynthutil
contract PynthUtil {
    IAddressResolver public addressResolverProxy;

    bytes32 internal constant CONTRACT_PYNTHETIX = "PeriFin";
    bytes32 internal constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 internal constant SUSD = "pUSD";

    constructor(address resolver) public {
        addressResolverProxy = IAddressResolver(resolver);
    }

    function _perifin() internal view returns (IPeriFin) {
        return IPeriFin(addressResolverProxy.requireAndGetAddress(CONTRACT_PYNTHETIX, "Missing PeriFin address"));
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(addressResolverProxy.requireAndGetAddress(CONTRACT_EXRATES, "Missing ExchangeRates address"));
    }

    function totalPynthsInKey(address account, bytes32 currencyKey) external view returns (uint total) {
        IPeriFin perifin = _perifin();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numPynths = perifin.availablePynthCount();
        for (uint i = 0; i < numPynths; i++) {
            IPynth pynth = perifin.availablePynths(i);
            total += exchangeRates.effectiveValue(
                pynth.currencyKey(),
                IERC20(address(pynth)).balanceOf(account),
                currencyKey
            );
        }
        return total;
    }

    function pynthsBalances(address account)
        external
        view
        returns (
            bytes32[] memory,
            uint[] memory,
            uint[] memory
        )
    {
        IPeriFin perifin = _perifin();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numPynths = perifin.availablePynthCount();
        bytes32[] memory currencyKeys = new bytes32[](numPynths);
        uint[] memory balances = new uint[](numPynths);
        uint[] memory pUSDBalances = new uint[](numPynths);
        for (uint i = 0; i < numPynths; i++) {
            IPynth pynth = perifin.availablePynths(i);
            currencyKeys[i] = pynth.currencyKey();
            balances[i] = IERC20(address(pynth)).balanceOf(account);
            pUSDBalances[i] = exchangeRates.effectiveValue(currencyKeys[i], balances[i], SUSD);
        }
        return (currencyKeys, balances, pUSDBalances);
    }

    function frozenPynths() external view returns (bytes32[] memory) {
        IPeriFin perifin = _perifin();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numPynths = perifin.availablePynthCount();
        bytes32[] memory frozenPynthsKeys = new bytes32[](numPynths);
        for (uint i = 0; i < numPynths; i++) {
            IPynth pynth = perifin.availablePynths(i);
            if (exchangeRates.rateIsFrozen(pynth.currencyKey())) {
                frozenPynthsKeys[i] = pynth.currencyKey();
            }
        }
        return frozenPynthsKeys;
    }

    function pynthsRates() external view returns (bytes32[] memory, uint[] memory) {
        bytes32[] memory currencyKeys = _perifin().availableCurrencyKeys();
        return (currencyKeys, _exchangeRates().ratesForCurrencies(currencyKeys));
    }

    function pynthsTotalSupplies()
        external
        view
        returns (
            bytes32[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        IPeriFin perifin = _perifin();
        IExchangeRates exchangeRates = _exchangeRates();

        uint256 numPynths = perifin.availablePynthCount();
        bytes32[] memory currencyKeys = new bytes32[](numPynths);
        uint256[] memory balances = new uint256[](numPynths);
        uint256[] memory pUSDBalances = new uint256[](numPynths);
        for (uint256 i = 0; i < numPynths; i++) {
            IPynth pynth = perifin.availablePynths(i);
            currencyKeys[i] = pynth.currencyKey();
            balances[i] = IERC20(address(pynth)).totalSupply();
            pUSDBalances[i] = exchangeRates.effectiveValue(currencyKeys[i], balances[i], SUSD);
        }
        return (currencyKeys, balances, pUSDBalances);
    }
}
