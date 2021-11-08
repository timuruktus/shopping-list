pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "BaseListDebot.sol";
import "ShoppingList.sol";

contract BuyerDebot is BaseListDebot{

    string private nameOfCurrentPurchase;

    function showMenu(PurchasesSummary summary) public override{
        string shoppingSummary = getFormattedShoppingSummary(summary);
        Menu.select(shoppingSummary, "",
            [
                MenuItem("Add product to shopping list", "", tvm.functionId(addToShoppingList)),
                MenuItem("Remove product from shopping list", "", tvm.functionId(removeFromShoppingList)),
                MenuItem("Show your shopping list", "", tvm.functionId(showShoppingList))
            ]
        );
    }

    function addToShoppingList() public{
        Terminal.input(tvm.functionId(onNameWritten), "Please, enter the name of your product", false);
    }

    function onNameWritten(string name) public{
        nameOfCurrentPurchase = name;
        Terminal.input(tvm.functionId(onAmountWritten), "Please, provide amount of items to purchase", false);
    }

    function onAmountWritten(string value) public{
        (uint amount, bool valid) = stoi(value);
        PurchasesContainer(contractAddress).addToPurchasesList{
            extMsg: true,
            abiVer: 2,
            sign: true,
            pubkey: userPubKey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(onProductAdded),
            onErrorId: tvm.functionId(onProductAddError)
        }(nameOfCurrentPurchase, amount);
    }

    function onProductAdded() public{
        Terminal.print(0, "You successfully added a new item in your shopping list");
        showData();
    }

    function onProductAddError() public{
        Terminal.print(0, "Error occured. Please, try again");
        addToShoppingList();
    }
    
}