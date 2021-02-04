pragma solidity ^0.5.16;


// Empty contract for ether collateral placeholder for OVM
// https://docs.perifin.io/contracts/source/contracts/emptyethercollateral
contract EmptyEtherCollateral {
    function totalIssuedPynths() external pure returns (uint) {
        return 0;
    }
}
