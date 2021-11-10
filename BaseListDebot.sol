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

    function printShoppingList(Purchase[] purchasesList) public{
        if(purchasesList.length == 0){
            Terminal.print(0, "You don't have any items in your shopping list. Try add something.");
            showData();
        } else{
            string list = "";
            for(uint i = 0; i < purchasesList.length; i++){
                Purchase purchase = purchasesList[i];
                string name = purchasesList[i].name;
                string purchased;
                uint id = purchase.id;
                uint price = purchase.totalPrice;
                if(purchase.purchased) purchased = "✔";
                else purchased = "✘";  
                Terminal.print(0, format("{}. {} {}. Price = {}", id, name, purchased, price));
            }
            showData();
        } 
    }

    function showShoppingList(uint32 index) public{
        optional(uint256) none;
        PurchasesContainer(contractAddress).getPurchasesList{
            extMsg: true,
            abiVer: 2,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(printShoppingList),
            onErrorId: tvm.functionId(showShoppingListError)
        }();
    }

    function showShoppingListError(uint32 sdkError, uint32 exitCode) public{
        Terminal.print(0, "Error. Try again!");
        showData();
    }

    function removeIdInput(uint32 index) public{
        Terminal.input(tvm.functionId(removeFromShoppingList), "Please, enter the id of the product to delete.", false);
    }

    function removeFromShoppingList(string value) public{
        (uint id, bool valid) = stoi(value);
        require(valid, 202);
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

    function onDeleteError(uint32 sdkError, uint32 exitCode) public{
        Terminal.print(0, "Error occured. Try another id");
        showData();
    }

    function onDeploySuccess() public override{
        showData();
    }

    function showData() public override{
        optional(uint256) none;
        PurchasesContainer(contractAddress).getPurchasesSummary{
            extMsg: true,
            abiVer: 2,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showMenu),
            onErrorId: tvm.functionId(showDataRepeat) // Just repeat.
        }();
    }

    function showDataRepeat(uint32 sdkError, uint32 exitCode) public{
        Terminal.print(0, "Some error occured while showing summary");
        showData();
    }

    function showMenu(PurchasesSummary summary) virtual public;


}