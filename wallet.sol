pragma solidity 0.8.3;

contract Wallet {
    
    address owner1; 
    address owner2;
    address owner3;
    uint approvalsLimit;
    uint balance;
    
    struct Transaction {
        uint amount;
        address payable receiver;
        uint numOfApprovals;
        bool hasBeenSent;
        uint id;
    }
    
    Transaction[] transactionRequests;
    mapping(address => mapping(uint => bool)) approvals;
    
    event depositDone (uint amount, address indexed fromAddress);
    event transactionRequestCreated(uint amount, address indexed receiver, address indexed creator);
    event transactionSigned(uint indexed transactionRequestId, address indexed signedBy, uint numOfApprovals);
    event transacionDone(uint indexed transactionRequestId, address indexed sentBy);

    constructor( address _owner2, address _owner3,uint _approvalsLimit ){
        owner1 = msg.sender;
        owner2 = _owner2;
        owner3 = _owner3;
        approvalsLimit = _approvalsLimit;
    }
    
    modifier onlyOwners(){
        require(
            msg.sender == owner1
            || msg.sender == owner2
            || msg.sender == owner3,
            "Only approver addresses can approve transactions."
        );
         _;//run the function
    }
    
    //Used to deposit money into the smart contract - not traking whose the money is
    function deposit() public payable{
        uint oldBalance = balance;
        balance += msg.value;
        emit depositDone (msg.value, msg.sender);
        assert(balance == oldBalance + msg.value);
    }

    //Before widthdraw the money we need to create a "transaction request"
    function createTransactionRequest(uint _amount, address payable _receiver) public onlyOwners{
        require(_amount <=balance, "There is not enough money");
        Transaction memory newTransaction = Transaction(_amount, _receiver, 0, false, transactionRequests.length);
        transactionRequests.push(newTransaction);
        emit transactionRequestCreated(_amount, _receiver, msg.sender);
    }
    
    //Used to approve the Transaction witch are on the Transaction request array
    //When the Transaction is approved ( more than 2 approves) the Transaction could be executed
    //require:
    //       1 - the Transaction not been sent 
    //       2 - there are no approvals from my address for that transactionId
    function approveTransaction(uint transactionRequestId)  public onlyOwners{
        require(transactionRequests[transactionRequestId].hasBeenSent == false, "This transaction has already been sent");
        require(approvals[msg.sender][transactionRequestId] == false, "You already approved this transaction");
        
        
        approvals[msg.sender][transactionRequestId] = true;
        transactionRequests[transactionRequestId].numOfApprovals++;
        
        
        Transaction memory transaction = transactionRequests[transactionRequestId];
        emit transactionSigned(transactionRequestId, msg.sender, transaction.numOfApprovals);
        
        if(transaction.numOfApprovals >= approvalsLimit){
            transactionRequests[transactionRequestId].hasBeenSent = true;
            uint oldBalance = balance;
             
            balance -= transaction.amount;
            transaction.receiver.transfer(transaction.amount);
            emit transacionDone(transactionRequestId, msg.sender);
            assert(balance == oldBalance - transaction.amount);

        }
        
    }
    
    function getTransactionRequests() public view returns ( Transaction[] memory)  {
        return transactionRequests;
    }
    
    function getBalance() public view returns(uint){
        return balance;
    }
    
}
