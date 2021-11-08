pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "BaseInitDebot.sol";

abstract contract BaseListDebot is BaseInitDebot{

    function getFormattedShoppingSummary(PurchasesSummary summary) internal returns(string){
        return format(
                "You have {}/{}/{} (Number of purchased items/Number of not purchased items/Total items price)",
                    summary.totalPaidAmount,
                    summary.totalNotPaidAmount,
                    summary.totalPaidPrice
            );
    }

    function printShoppingList(Purchase[] purchasesList) internal returns(string){
        if(purchasesList.length == 0) return "You don't have any items in your shopping list. Try add something.";
        else{
            string list = "";
            for(uint i = 0; i < purchasesList.length; i++){
                Purchase purchase = purchasesList[i];
                string name = purchasesList[i].name;
                string purchased;
                uint id = purchase.id;
                if(purchase.purchased) purchased = "✔";
                else purchased = "✘";  
                Terminal.print(0, format("{}. {} {}", id, name, purchased));
            }
        } 
    }

    function showShoppingList() public{
        PurchasesContainer(contractAddress).getPurchasesList{
            extMsg: true,
            abiVer: 2,
            sign: true,
            pubkey: userPubKey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(_showShoppingList),
            onErrorId: tvm.functionId(showShoppingListRepeat) // Just repeat.
        }();
    }

    function _showShoppingList(Purchase[] purchases) public{
        printShoppingList(purchases);
    }

    function showShoppingListRepeat() public{
        showShoppingList();
    }

    function removeFromShoppingList() public{
        Terminal.input(tvm.functionId(_removeFromShoppingList), "Please, enter the id of the product to delete.", false);
    }

    function _removeFromShoppingList(string value) public{
        (uint id, bool valid) = stoi(value);
        if(!valid){
            onDeleteError();
            return;
        } 
        PurchasesContainer(contractAddress).deleteFromPurchasesList{
            extMsg: true,
            abiVer: 2,
            sign: true,
            pubkey: userPubKey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(successfullyDeleted),
            onErrorId: tvm.functionId(onDeleteError)
        }(id);
    }

    function successfullyDeleted() virtual public{
        Terminal.print(0, "Your item was successfully deleted.");
        showData();
    }

    function onDeleteError() public{
        Terminal.print(0, "Error occured. Try another id");
        showData();
    }

    function onDeploySuccess() public override{
        showData();
    }

    function showData() public override{
        PurchasesContainer(contractAddress).getPurchasesSummary{
            extMsg: true,
            abiVer: 2,
            sign: true,
            pubkey: userPubKey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showMenu),
            onErrorId: tvm.functionId(showDataRepeat) // Just repeat.
        }();
    }

    function showDataRepeat() public{
        showData();
    }

    function showMenu(PurchasesSummary summary) virtual public;


}