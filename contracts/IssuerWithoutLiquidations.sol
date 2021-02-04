pragma solidity ^0.5.16;

// Internal references
import "./Issuer.sol";


// /contracts/source/contracts/issuerwithoutliquidations
contract IssuerWithoutLiquidations is Issuer {
    constructor(address _owner, address _resolver) public Issuer(_owner, _resolver) {}

    function liquidateDelinquentAccount(
        address account,
        uint susdAmount,
        address liquidator
    ) external onlyPeriFin returns (uint totalRedeemed, uint amountToLiquidate) {}
}
