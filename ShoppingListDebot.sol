pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "BaseListDebot.sol";
import "ShoppingList.sol";

contract ShoppingListDebot is BaseListDebot{

    string private nameOfCurrentPurchase;

    function showMenu(PurchasesSummary summary) public override{
        string shoppingSummary = getFormattedShoppingSummary(summary);
        Menu.select(shoppingSummary, "",
            [
                MenuItem("Add product to shopping list", "", tvm.functionId(addNameInput)),
                MenuItem("Remove product from shopping list", "", tvm.functionId(removeIdInput)),
                MenuItem("Show my shopping list", "", tvm.functionId(showShoppingList))
            ]
        );
    }

    function addNameInput(uint32 index) public{
        index = index;
        Terminal.input(tvm.functionId(addAmountInput), "Please, enter the name of your product", false);
    }

    function addAmountInput(string value) public{
        nameOfCurrentPurchase = value;
        Terminal.input(tvm.functionId(addToShoppingList), "Please, provide amount of items to purchase", false);
    }

    function addToShoppingList(string value) public{
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

    function onProductAddError(uint32 sdkError, uint32 exitCode) public{
        Terminal.print(0, "Error occured. Please, try again");
        addNameInput(0);
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Shopping list DeBot";
        version = "1.0.0";
        publisher = "Timur Khasanov";
        caption = "Here you can add products to your product list.";
        author = "Timur Khasanov";
        support = address.makeAddrStd(0, 0x1e3713373c839489cd84f0745d7f98a0ba3bcdbd91a56ac30c79f769303ec603);
        hello = "Welcome to Shopping list DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = iconPath;
    }
    
}