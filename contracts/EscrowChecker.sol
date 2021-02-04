pragma solidity ^0.5.16;


interface IPeriFinEscrow {
    function numVestingEntries(address account) external view returns (uint);

    function getVestingScheduleEntry(address account, uint index) external view returns (uint[2] memory);
}


// https://docs.perifin.io/contracts/source/contracts/escrowchecker
contract EscrowChecker {
    IPeriFinEscrow public perifin_escrow;

    constructor(IPeriFinEscrow _esc) public {
        perifin_escrow = _esc;
    }

    function checkAccountSchedule(address account) public view returns (uint[16] memory) {
        uint[16] memory _result;
        uint schedules = perifin_escrow.numVestingEntries(account);
        for (uint i = 0; i < schedules; i++) {
            uint[2] memory pair = perifin_escrow.getVestingScheduleEntry(account, i);
            _result[i * 2] = pair[0];
            _result[i * 2 + 1] = pair[1];
        }
        return _result;
    }
}
