pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";
import "./interfaces/ISystemStatus.sol";


// /contracts/source/contracts/systemstatus
contract SystemStatus is Owned, ISystemStatus {
    mapping(bytes32 => mapping(address => Status)) public accessControl;

    uint248 public constant SUSPENSION_REASON_UPGRADE = 1;

    bytes32 public constant SECTION_SYSTEM = "System";
    bytes32 public constant SECTION_ISSUANCE = "Issuance";
    bytes32 public constant SECTION_EXCHANGE = "Exchange";
    bytes32 public constant SECTION_PYNTH = "Pynth";

    Suspension public systemSuspension;

    Suspension public issuanceSuspension;

    Suspension public exchangeSuspension;

    mapping(bytes32 => Suspension) public pynthSuspension;

    constructor(address _owner) public Owned(_owner) {
        _internalUpdateAccessControl(SECTION_SYSTEM, _owner, true, true);
        _internalUpdateAccessControl(SECTION_ISSUANCE, _owner, true, true);
        _internalUpdateAccessControl(SECTION_EXCHANGE, _owner, true, true);
        _internalUpdateAccessControl(SECTION_PYNTH, _owner, true, true);
    }

    /* ========== VIEWS ========== */
    function requireSystemActive() external view {
        _internalRequireSystemActive();
    }

    function requireIssuanceActive() external view {
        // Issuance requires the system be active
        _internalRequireSystemActive();
        require(!issuanceSuspension.suspended, "Issuance is suspended. Operation prohibited");
    }

    function requireExchangeActive() external view {
        // Issuance requires the system be active
        _internalRequireSystemActive();
        require(!exchangeSuspension.suspended, "Exchange is suspended. Operation prohibited");
    }

    function requirePynthActive(bytes32 currencyKey) external view {
        // Pynth exchange and transfer requires the system be active
        _internalRequireSystemActive();
        require(!pynthSuspension[currencyKey].suspended, "Pynth is suspended. Operation prohibited");
    }

    function requirePynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view {
        // Pynth exchange and transfer requires the system be active
        _internalRequireSystemActive();

        require(
            !pynthSuspension[sourceCurrencyKey].suspended && !pynthSuspension[destinationCurrencyKey].suspended,
            "One or more pynths are suspended. Operation prohibited"
        );
    }

    function isSystemUpgrading() external view returns (bool) {
        return systemSuspension.suspended && systemSuspension.reason == SUSPENSION_REASON_UPGRADE;
    }

    function getPynthSuspensions(bytes32[] calldata pynths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons)
    {
        suspensions = new bool[](pynths.length);
        reasons = new uint256[](pynths.length);

        for (uint i = 0; i < pynths.length; i++) {
            suspensions[i] = pynthSuspension[pynths[i]].suspended;
            reasons[i] = pynthSuspension[pynths[i]].reason;
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external onlyOwner {
        _internalUpdateAccessControl(section, account, canSuspend, canResume);
    }

    function suspendSystem(uint256 reason) external {
        _requireAccessToSuspend(SECTION_SYSTEM);
        systemSuspension.suspended = true;
        systemSuspension.reason = uint248(reason);
        emit SystemSuspended(systemSuspension.reason);
    }

    function resumeSystem() external {
        _requireAccessToResume(SECTION_SYSTEM);
        systemSuspension.suspended = false;
        emit SystemResumed(uint256(systemSuspension.reason));
        systemSuspension.reason = 0;
    }

    function suspendIssuance(uint256 reason) external {
        _requireAccessToSuspend(SECTION_ISSUANCE);
        issuanceSuspension.suspended = true;
        issuanceSuspension.reason = uint248(reason);
        emit IssuanceSuspended(reason);
    }

    function resumeIssuance() external {
        _requireAccessToResume(SECTION_ISSUANCE);
        issuanceSuspension.suspended = false;
        emit IssuanceResumed(uint256(issuanceSuspension.reason));
        issuanceSuspension.reason = 0;
    }

    function suspendExchange(uint256 reason) external {
        _requireAccessToSuspend(SECTION_EXCHANGE);
        exchangeSuspension.suspended = true;
        exchangeSuspension.reason = uint248(reason);
        emit ExchangeSuspended(reason);
    }

    function resumeExchange() external {
        _requireAccessToResume(SECTION_EXCHANGE);
        exchangeSuspension.suspended = false;
        emit ExchangeResumed(uint256(exchangeSuspension.reason));
        exchangeSuspension.reason = 0;
    }

    function suspendPynth(bytes32 currencyKey, uint256 reason) external {
        _requireAccessToSuspend(SECTION_PYNTH);
        pynthSuspension[currencyKey].suspended = true;
        pynthSuspension[currencyKey].reason = uint248(reason);
        emit PynthSuspended(currencyKey, reason);
    }

    function resumePynth(bytes32 currencyKey) external {
        _requireAccessToResume(SECTION_PYNTH);
        emit PynthResumed(currencyKey, uint256(pynthSuspension[currencyKey].reason));
        delete pynthSuspension[currencyKey];
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _requireAccessToSuspend(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canSuspend, "Restricted to access control list");
    }

    function _requireAccessToResume(bytes32 section) internal view {
        require(accessControl[section][msg.sender].canResume, "Restricted to access control list");
    }

    function _internalRequireSystemActive() internal view {
        require(
            !systemSuspension.suspended,
            systemSuspension.reason == SUSPENSION_REASON_UPGRADE
                ? "PeriFin is suspended, upgrade in progress... please stand by"
                : "PeriFin is suspended. Operation prohibited"
        );
    }

    function _internalUpdateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) internal {
        require(
            section == SECTION_SYSTEM ||
                section == SECTION_ISSUANCE ||
                section == SECTION_EXCHANGE ||
                section == SECTION_PYNTH,
            "Invalid section supplied"
        );
        accessControl[section][account].canSuspend = canSuspend;
        accessControl[section][account].canResume = canResume;
        emit AccessControlUpdated(section, account, canSuspend, canResume);
    }

    /* ========== EVENTS ========== */

    event SystemSuspended(uint256 reason);
    event SystemResumed(uint256 reason);

    event IssuanceSuspended(uint256 reason);
    event IssuanceResumed(uint256 reason);

    event ExchangeSuspended(uint256 reason);
    event ExchangeResumed(uint256 reason);

    event PynthSuspended(bytes32 currencyKey, uint256 reason);
    event PynthResumed(bytes32 currencyKey, uint256 reason);

    event AccessControlUpdated(bytes32 indexed section, address indexed account, bool canSuspend, bool canResume);
}
