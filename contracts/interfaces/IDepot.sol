pragma solidity >=0.4.24;


// https://docs.perifin.io/contracts/source/interfaces/idepot
interface IDepot {
    // Views
    function fundsWallet() external view returns (address payable);

    function maxEthPurchase() external view returns (uint);

    function minimumDepositAmount() external view returns (uint);

    function pynthsReceivedForEther(uint amount) external view returns (uint);

    function totalSellableDeposits() external view returns (uint);

    // Mutative functions
    function depositPynths(uint amount) external;

    function exchangeEtherForPynths() external payable returns (uint);

    function exchangeEtherForPynthsAtRate(uint guaranteedRate) external payable returns (uint);

    function withdrawMyDepositedPynths() external;

    // Note: On mainnet no PERI has been deposited. The following functions are kept alive for testnet PERI faucets.
    function exchangeEtherForPERI() external payable returns (uint);

    function exchangeEtherForPERIAtRate(uint guaranteedRate, uint guaranteedPeriFinRate) external payable returns (uint);

    function exchangePynthsForPERI(uint pynthAmount) external returns (uint);

    function perifinReceivedForEther(uint amount) external view returns (uint);

    function perifinReceivedForPynths(uint amount) external view returns (uint);

    function withdrawPeriFin(uint amount) external;
}
