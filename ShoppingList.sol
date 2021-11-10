pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "Structures.sol";

contract ShoppingList is PurchasesContainer{

    uint ownerPubKey;
    uint nextPurchaseId;
    mapping(uint => Purchase) idToPurchaseMapping;

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
        idToPurchaseMapping[nextPurchaseId] = Purchase(nextPurchaseId, name, amount, now, false, 0, false);
    }

    function deleteFromPurchasesList(uint id) public override onlyOwner{
        require(!idToPurchaseMapping[id].deleted, 104);
        if(idToPurchaseMapping.exists(id)){
            tvm.accept();
            idToPurchaseMapping[id].deleted = true;
        }
    }

    function buy(uint id, uint price) public override onlyOwner{
        optional(Purchase) purchaseToBuy = idToPurchaseMapping.fetch(id);
        require(purchaseToBuy.hasValue(), 103);
        require(!idToPurchaseMapping[id].deleted, 104);
        tvm.accept();
        idToPurchaseMapping[id].totalPrice = price;
        idToPurchaseMapping[id].purchased = true;
    }

    function getPurchasesSummary() public override returns(PurchasesSummary){
        tvm.accept();
        PurchasesSummary summary;
        for((uint id, Purchase purchaseToBuy) : idToPurchaseMapping){
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

        for((uint _id, Purchase purchase) : idToPurchaseMapping) {
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