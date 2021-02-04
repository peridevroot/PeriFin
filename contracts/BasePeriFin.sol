pragma solidity ^0.5.16;

// Inheritance
import "./interfaces/IERC20.sol";
import "./ExternStateToken.sol";
import "./MixinResolver.sol";
import "./interfaces/IPeriFin.sol";

// Internal references
import "./interfaces/IPynth.sol";
import "./TokenState.sol";
import "./interfaces/IPeriFinState.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/IRewardsDistribution.sol";
import "./interfaces/IVirtualPynth.sol";


contract BasePeriFin is IERC20, ExternStateToken, MixinResolver, IPeriFin {
    // ========== STATE VARIABLES ==========

    // Available Pynths which can be used with the system
    string public constant TOKEN_NAME = "PeriFin Network Token";
    string public constant TOKEN_SYMBOL = "PERI";
    uint8 public constant DECIMALS = 18;
    bytes32 public constant pUSD = "pUSD";

    // ========== ADDRESS RESOLVER CONFIGURATION ==========
    bytes32 private constant CONTRACT_PYNTHETIXSTATE = "PeriFinState";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_REWARDSDISTRIBUTION = "RewardsDistribution";

    // ========== CONSTRUCTOR ==========

    constructor(
        address payable _proxy,
        TokenState _tokenState,
        address _owner,
        uint _totalSupply,
        address _resolver
    )
        public
        ExternStateToken(_proxy, _tokenState, TOKEN_NAME, TOKEN_SYMBOL, _totalSupply, DECIMALS, _owner)
        MixinResolver(_resolver)
    {}

    // ========== VIEWS ==========

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](5);
        addresses[0] = CONTRACT_PYNTHETIXSTATE;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_EXCHANGER;
        addresses[3] = CONTRACT_ISSUER;
        addresses[4] = CONTRACT_REWARDSDISTRIBUTION;
    }

    function perifinState() internal view returns (IPeriFinState) {
        return IPeriFinState(requireAndGetAddress(CONTRACT_PYNTHETIXSTATE));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function rewardsDistribution() internal view returns (IRewardsDistribution) {
        return IRewardsDistribution(requireAndGetAddress(CONTRACT_REWARDSDISTRIBUTION));
    }

    function debtBalanceOf(address account, bytes32 currencyKey) external view returns (uint) {
        return issuer().debtBalanceOf(account, currencyKey);
    }

    function totalIssuedPynths(bytes32 currencyKey) external view returns (uint) {
        return issuer().totalIssuedPynths(currencyKey, false);
    }

    function totalIssuedPynthsExcludeEtherCollateral(bytes32 currencyKey) external view returns (uint) {
        return issuer().totalIssuedPynths(currencyKey, true);
    }

    function availableCurrencyKeys() external view returns (bytes32[] memory) {
        return issuer().availableCurrencyKeys();
    }

    function availablePynthCount() external view returns (uint) {
        return issuer().availablePynthCount();
    }

    function availablePynths(uint index) external view returns (IPynth) {
        return issuer().availablePynths(index);
    }

    function pynths(bytes32 currencyKey) external view returns (IPynth) {
        return issuer().pynths(currencyKey);
    }

    function pynthsByAddress(address pynthAddress) external view returns (bytes32) {
        return issuer().pynthsByAddress(pynthAddress);
    }

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool) {
        return exchanger().maxSecsLeftInWaitingPeriod(messageSender, currencyKey) > 0;
    }

    function anyPynthOrPERIRateIsInvalid() external view returns (bool anyRateInvalid) {
        return issuer().anyPynthOrPERIRateIsInvalid();
    }

    function maxIssuablePynths(address account) external view returns (uint maxIssuable) {
        return issuer().maxIssuablePynths(account);
    }

    function remainingIssuablePynths(address account)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        )
    {
        return issuer().remainingIssuablePynths(account);
    }

    function collateralisationRatio(address _issuer) external view returns (uint) {
        return issuer().collateralisationRatio(_issuer);
    }

    function collateral(address account) external view returns (uint) {
        return issuer().collateral(account);
    }

    function transferablePeriFin(address account) external view returns (uint transferable) {
        (transferable, ) = issuer().transferablePeriFinAndAnyRateIsInvalid(account, tokenState.balanceOf(account));
    }

    function _canTransfer(address account, uint value) internal view returns (bool) {
        (uint initialDebtOwnership, ) = perifinState().issuanceData(account);

        if (initialDebtOwnership > 0) {
            (uint transferable, bool anyRateIsInvalid) = issuer().transferablePeriFinAndAnyRateIsInvalid(
                account,
                tokenState.balanceOf(account)
            );
            require(value <= transferable, "Cannot transfer staked or escrowed PERI");
            require(!anyRateIsInvalid, "A pynth or PERI rate is invalid");
        }
        return true;
    }

    // ========== MUTATIVE FUNCTIONS ==========

    function transfer(address to, uint value) external optionalProxy systemActive returns (bool) {
        // Ensure they're not trying to exceed their locked amount -- only if they have debt.
        _canTransfer(messageSender, value);

        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferByProxy(messageSender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint value
    ) external optionalProxy systemActive returns (bool) {
        // Ensure they're not trying to exceed their locked amount -- only if they have debt.
        _canTransfer(from, value);

        // Perform the transfer: if there is a problem,
        // an exception will be thrown in this call.
        return _transferFromByProxy(messageSender, from, to, value);
    }

    function issuePynths(uint amount) external issuanceActive optionalProxy {
        return issuer().issuePynths(messageSender, amount);
    }

    function issuePynthsOnBehalf(address issueForAddress, uint amount) external issuanceActive optionalProxy {
        return issuer().issuePynthsOnBehalf(issueForAddress, messageSender, amount);
    }

    function issueMaxPynths() external issuanceActive optionalProxy {
        return issuer().issueMaxPynths(messageSender);
    }

    function issueMaxPynthsOnBehalf(address issueForAddress) external issuanceActive optionalProxy {
        return issuer().issueMaxPynthsOnBehalf(issueForAddress, messageSender);
    }

    function burnPynths(uint amount) external issuanceActive optionalProxy {
        return issuer().burnPynths(messageSender, amount);
    }

    function burnPynthsOnBehalf(address burnForAddress, uint amount) external issuanceActive optionalProxy {
        return issuer().burnPynthsOnBehalf(burnForAddress, messageSender, amount);
    }

    function burnPynthsToTarget() external issuanceActive optionalProxy {
        return issuer().burnPynthsToTarget(messageSender);
    }

    function burnPynthsToTargetOnBehalf(address burnForAddress) external issuanceActive optionalProxy {
        return issuer().burnPynthsToTargetOnBehalf(burnForAddress, messageSender);
    }

    function exchange(
        bytes32,
        uint,
        bytes32
    ) external returns (uint) {
        _notImplemented();
    }

    function exchangeOnBehalf(
        address,
        bytes32,
        uint,
        bytes32
    ) external returns (uint) {
        _notImplemented();
    }

    function exchangeWithTracking(
        bytes32,
        uint,
        bytes32,
        address,
        bytes32
    ) external returns (uint) {
        _notImplemented();
    }

    function exchangeOnBehalfWithTracking(
        address,
        bytes32,
        uint,
        bytes32,
        address,
        bytes32
    ) external returns (uint) {
        _notImplemented();
    }

    function exchangeWithVirtual(
        bytes32,
        uint,
        bytes32,
        bytes32
    ) external returns (uint, IVirtualPynth) {
        _notImplemented();
    }

    function settle(bytes32)
        external
        returns (
            uint,
            uint,
            uint
        )
    {
        _notImplemented();
    }

    function mint() external returns (bool) {
        _notImplemented();
    }

    function liquidateDelinquentAccount(address, uint) external returns (bool) {
        _notImplemented();
    }

    function mintSecondary(address, uint) external {
        _notImplemented();
    }

    function mintSecondaryRewards(uint) external {
        _notImplemented();
    }

    function burnSecondary(address, uint) external {
        _notImplemented();
    }

    function _notImplemented() internal pure {
        revert("Cannot be run on this layer");
    }

    // ========== MODIFIERS ==========

    modifier systemActive() {
        _systemActive();
        _;
    }

    function _systemActive() private {
        systemStatus().requireSystemActive();
    }

    modifier issuanceActive() {
        _issuanceActive();
        _;
    }

    function _issuanceActive() private {
        systemStatus().requireIssuanceActive();
    }
}
