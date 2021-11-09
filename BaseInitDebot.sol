pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "Structures.sol";
import "./core/Terminal.sol";
import "./core/Sdk.sol";
import "./core/AddressInput.sol";
import "./core/ConfirmInput.sol";
import "./core/Debot.sol";
import "./core/Menu.sol";

abstract contract BaseInitDebot is Debot{
    
    uint userPubKey;
    bytes iconPath;
    TvmCell contractStateInit;
    address contractAddress;
    address creationAccount;
    int8 constant ACTIVE = 1;
    int8 constant NOT_ENOUGH_BALANCE = -1;
    int8 constant NOT_DEPLOYED = 0;
    int8 constant FROZEN = 2;
    uint32 INITIAL_BALANCE =  200000000; // 0.2 TON
    

    function start() public override{
        Terminal.input(tvm.functionId(savePublicKey),"Hello. Please enter your public key",false);
    }

    function setContractCode(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        contractStateInit = tvm.buildStateInit(code, data);
    }

    function savePublicKey(string value) public {
        (uint res, bool valid) = stoi("0x"+value);
        if(valid) {
            userPubKey = res;
            Terminal.print(0, "Checking if you already have a Shopping list. Please wait ...");
            TvmCell deployState = tvm.insertPubkey(contractStateInit, userPubKey);
            contractAddress = address.makeAddrStd(0, tvm.hash(deployState));
            Terminal.print(0, format( "Info: your Shopping list contract address is: {}", contractAddress));
            Sdk.getAccountType(tvm.functionId(checkAccountType), contractAddress);
        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Wrong public key. Try again!\nPlease enter your public key",false);
        }
    }

    function checkAccountType(int8 acc_type) public {
        if(acc_type == ACTIVE) { 
            Terminal.print(0, "Your account is ready");
            showData();
        }else if(acc_type == NOT_ENOUGH_BALANCE)  { 
            Terminal.print(0, "You don't have a Shopping list yet, so a new contract with an initial balance of 0.2 tokens will be deployed");
            AddressInput.get(tvm.functionId(creditAccount),"Select a wallet for payment. We will ask you to sign two transactions.");
        }else if(acc_type == NOT_DEPLOYED) { 
            Terminal.print(0, format(
                "Deploying new contract. If an error occurs, check if your Shopping list contract has enough tokens on its balance."
            ));
            deploy();
        }else if(acc_type == FROZEN) {  
            Terminal.print(0, format("Can not continue: account {} is frozen", contractAddress));
        }
    }

    function creditAccount(address value) public {
        creationAccount = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        Transactable(creationAccount).sendTransaction{
            extMsg: true,
            abiVer: 2,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeCredit),
            onErrorId: tvm.functionId(onCreditError)
        }(contractAddress, INITIAL_BALANCE, false, 3, empty);
    }

    function onCreditError(uint32 sdkError, uint32 exitCode) public{
        ConfirmInput.get(tvm.functionId(onCreditErrorAnswer), "Error occured during creation. Please, check your wallet balance. Try again?");
    }

    function onCreditErrorAnswer(bool tryAgain) public{
        if(tryAgain){
            creditAccount(creationAccount);
        }else{
            start();
        }
    }

    function deploy() private view {
        TvmCell image = tvm.insertPubkey(contractStateInit, userPubKey);
        optional(uint256) none;
        TvmCell deployMsg = tvm.buildExtMsg({
            abiVer: 2,
            dest: contractAddress,
            callbackId: tvm.functionId(onDeploySuccess),
            onErrorId:  tvm.functionId(onDeployError),    // Just repeat if something went wrong
            time: 0,
            expire: 0,
            sign: true,
            pubkey: none,
            stateInit: image,
            call: {HasConstructorWithPubKey, userPubKey}
        });
        tvm.sendrawmsg(deployMsg, 1);
    }

    function onDeployError() public{
        ConfirmInput.get(tvm.functionId(onDeployErrorAnswer), "Error occured during deploy. Please, check your wallet balance. Try again?");
    }

    function onDeployErrorAnswer(bool tryAgain) public{
        if(tryAgain){
            deploy();
        }else{
            start();
        }
    }

    function waitBeforeCredit() public  {
        Sdk.getAccountType(tvm.functionId(checkIfContractHasBalance), contractAddress);
    }

    function checkIfContractHasBalance(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeCredit();
        }
    }

    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Shopping list DeBot";
        version = "0.2.0";
        publisher = "Timur Khasanov";
        caption = "Shopping list manager";
        author = "Timur Khasanov";
        support = address.makeAddrStd(0, 0x1e3713373c839489cd84f0745d7f98a0ba3bcdbd91a56ac30c79f769303ec603);
        hello = "Hi, i'm a Shopping list DeBot.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = iconPath;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function onDeploySuccess() virtual public;
    

    function showData() virtual public;

}