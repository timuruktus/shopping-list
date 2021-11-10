pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "Structures.sol";
import "BaseListDebot.sol";

contract BuyerDebot is BaseListDebot{

    uint private idToBuy;

    function showMenu(PurchasesSummary summary) public override{
        string shoppingSummary = getFormattedShoppingSummary(summary);
        Menu.select(shoppingSummary, "",
            [
                MenuItem("Buy product from shopping list", "", tvm.functionId(buyIdInput)),
                MenuItem("Remove product from shopping list", "", tvm.functionId(removeIdInput)),
                MenuItem("Show my shopping list", "", tvm.functionId(showShoppingList))
            ]
        );
    }

    function buyIdInput(uint32 index) public{
        index = index;
        Terminal.input(tvm.functionId(buyPriceInput), "Please, enter product id to buy", false);
    }

    function buyPriceInput(string value) public{
        (uint id, bool valid) = stoi(value);
        idToBuy = id;
        Terminal.input(tvm.functionId(buyProduct), "Please, enter price of the product", false);
    }

    function buyProduct(string value) public{ 
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

    function onBoughtError(uint32 sdkError, uint32 exitCode) public{
        Terminal.print(0, "Error occured. Please, try another id.");
        showData();
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Buyer DeBot";
        version = "1.0.0";
        publisher = "Timur Khasanov";
        caption = "Here you can buy items from your puchases list.";
        author = "Timur Khasanov";
        support = address.makeAddrStd(0, 0x1e3713373c839489cd84f0745d7f98a0ba3bcdbd91a56ac30c79f769303ec603);
        hello = "Welcome to Buyer DeBot";
        language = "en";
        dabi = m_debotAbi.get();
        icon = iconPath;
    }

}