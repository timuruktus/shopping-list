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
        purchases[nextPurchaseId] = Purchase(nextPurchaseId, name, amount, now, false, 0);
    }

    function deleteFromPurchasesList(uint id) public override{
        require(purchases.exists(id), 102);
        tvm.accept();
        delete purchases[id];
    }

    function buy(uint id, uint price) public override{
        optional(Purchase) purchaseToBuy = purchases.fetch(id);
        require(purchaseToBuy.hasValue(), 102);
        tvm.accept();
        purchases[id].totalPrice = price;
        purchases[id].purchased = true;
    }

    function getPurchasesSummary() public override returns(PurchasesSummary){
        tvm.accept();
        PurchasesSummary summary;
        for((uint id, Purchase purchaseToBuy) : purchases){
            if(purchaseToBuy.purchased){
                summary.totalPaidAmount += purchaseToBuy.amount;
                summary.totalPaidPrice += purchaseToBuy.totalPrice;
            } else{
                summary.totalNotPaidAmount += purchaseToBuy.amount;
            } 
        }
        return summary;
    }

    function getPurchasesList() public override returns(Purchase[]){
        Purchase[] purchasesList;
        for((uint id, Purchase purchaseToBuy) : purchases){
            purchasesList.push(purchaseToBuy);
        }
        return purchasesList;
    }
}