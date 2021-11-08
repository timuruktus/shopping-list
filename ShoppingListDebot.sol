pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "Structures.sol";
import "BaseListDebot.sol";

contract ShoppingListDebot is BaseListDebot{

    uint private idToBuy;

    function showMenu(PurchasesSummary summary) public override{
        string shoppingSummary = getFormattedShoppingSummary(summary);
        Menu.select(shoppingSummary, "",
            [
                MenuItem("Buy product from shopping list", "", tvm.functionId(buyProduct)),
                MenuItem("Remove product from shopping list", "", tvm.functionId(removeFromShoppingList)),
                MenuItem("Show your shopping list", "", tvm.functionId(showShoppingList))
            ]
        );
    }

    function buyProduct() public{
        Terminal.input(tvm.functionId(_buyProduct), "Please, enter product id to buy", false);
    }

    function _buyProduct(string value) public{
        (uint id, bool valid) = stoi(value);
        idToBuy = id;
        Terminal.input(tvm.functionId(__buyProduct), "Please, enter price of the product", false);
    }

    function __buyProduct(string value) public{ 
        (uint price, bool valid) = stoi(value);
        PurchasesContainer(contractAddress).buy{
            extMsg: true,
            abiVer: 2,
            sign: true,
            pubkey: userPubKey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(onProductBought),
            onErrorId: tvm.functionId(onBoughtError)
        }(idToBuy, price);
    }

    function onProductBought() public{
        Terminal.print(0, "You bought the product.");
        showData();
    }

    function onBoughtError() public{
        Terminal.print(0, "Error occured. Please, try another id.");
        showData();
    }

}