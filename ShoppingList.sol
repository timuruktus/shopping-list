pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "Structures.sol";

contract ShoppingList is PurchasesContainer{

    uint ownerPubKey;
    uint nextPurchaseId;
    mapping(uint => Purchase) purchases;

    constructor(uint pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        nextPurchaseId = 0;
        ownerPubKey = pubkey;
    }

    modifier onlyOwner(){
        require(msg.pubkey() == ownerPubKey, 200);
        _;
    }

    function addToPurchasesList(string name, uint amount) public override onlyOwner{
        tvm.accept();
        nextPurchaseId++;
        purchases[nextPurchaseId] = Purchase(nextPurchaseId, name, amount, now, false, 0, false);
    }

    function deleteFromPurchasesList(uint id) public override onlyOwner{
        require(!purchases[id].deleted, 104);
        if(purchases.exists(id)){
            tvm.accept();
            purchases[id].deleted = true;
        }
    }

    function buy(uint id, uint price) public override onlyOwner{
        optional(Purchase) purchaseToBuy = purchases.fetch(id);
        require(purchaseToBuy.hasValue(), 103);
        require(!purchases[id].deleted, 104);
        tvm.accept();
        purchases[id].totalPrice = price;
        purchases[id].purchased = true;
    }

    function getPurchasesSummary() public override returns(PurchasesSummary){
        tvm.accept();
        PurchasesSummary summary;
        for((uint id, Purchase purchaseToBuy) : purchases){
            if(!purchaseToBuy.deleted){
                if(purchaseToBuy.purchased){
                    summary.totalPaidAmount += purchaseToBuy.amount;
                    summary.totalPaidPrice += purchaseToBuy.totalPrice;
                } else{
                    summary.totalNotPaidAmount += purchaseToBuy.amount;
                } 
            }
        }
        return summary;
    }

    function getPurchasesList() public override returns(Purchase[] purchasesList){
        uint id;
        string name;
        uint amount;
        uint whenCreated;
        bool purchased;
        uint totalPrice;
        bool deleted;

        for((uint _id, Purchase purchase) : purchases) {
            if(!purchase.deleted){
                id = _id;
                name = purchase.name;
                amount = purchase.amount;
                whenCreated = purchase.whenCreated;
                purchased = purchase.purchased;
                totalPrice = purchase.totalPrice;
                purchasesList.push(Purchase(id, name, amount, whenCreated, purchased, totalPrice, false));
            }
       }
    }
}