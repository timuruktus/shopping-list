pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

struct Purchase{
    uint id;
    string name;
    uint amount;
    uint whenCreated;
    bool purchased;
    uint totalPrice;
}

struct PurchasesSummary{
    uint256 totalPaidAmount;
    uint256 totalNotPaidAmount;
    uint256 totalPaidPrice;
}

interface PurchasesContainer {
    function getPurchasesSummary() external returns (PurchasesSummary);
    function getPurchasesList() external returns(Purchase[]);
    function addToPurchasesList(string name, uint amount) external;
    function deleteFromPurchasesList(uint id) external;
    function buy(uint id, uint price) external;
}

interface Transactable{
    function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}

abstract contract HasConstructorWithPubKey {
    constructor(uint pubkey) public {}
}