// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MultiSigWallet
 * @author Your Name
 * @notice This contract implements a multi-signature wallet requiring multiple approvals for transactions
 * @dev All transactions require a minimum of 2 confirmations from the signers
 */
contract MultiSigWallet {
    // Events
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    // State variables
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(address => bool) public isSigner;
    address[] public signers;
    uint256 public constant MIN_SIGNERS = 3;
    uint256 public constant REQUIRED_CONFIRMATIONS = 2;

    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;

    // Modifiers
    modifier onlySigner() {
        require(isSigner[msg.sender], "Not a signer");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(
            !transactions[_txIndex].executed,
            "Transaction already executed"
        );
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(
            !isConfirmed[_txIndex][msg.sender],
            "Transaction already confirmed"
        );
        _;
    }

    /**
     * @notice Constructs a new MultiSigWallet with initial signers
     * @param _signers Array of initial signer addresses
     */
    constructor(address[] memory _signers) {
        require(_signers.length >= MIN_SIGNERS, "Must have minimum signers");

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0), "Invalid signer");
            require(!isSigner[signer], "Signer not unique");

            isSigner[signer] = true;
            signers.push(signer);
            emit SignerAdded(signer);
        }
    }

    /**
     * @notice Submits a new transaction to the wallet
     * @param _to Destination address
     * @param _value Amount of ETH to send
     * @param _data Transaction data payload
     * @return txIndex Index of submitted transaction
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) public onlySigner returns (uint256 txIndex) {
        txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /**
     * @notice Confirms a submitted transaction
     * @param _txIndex Index of the transaction to confirm
     */
    function confirmTransaction(
        uint256 _txIndex
    )
        public
        onlySigner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);

        if (transaction.numConfirmations >= REQUIRED_CONFIRMATIONS) {
            executeTransaction(_txIndex);
        }
    }

    /**
     * @notice Revokes a confirmation for a transaction
     * @param _txIndex Index of the transaction
     */
    function revokeConfirmation(
        uint256 _txIndex
    ) public onlySigner txExists(_txIndex) notExecuted(_txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "Transaction not confirmed");

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @notice Adds a new signer to the wallet
     * @param _newSigner Address of the new signer
     */
    function addSigner(address _newSigner) public onlySigner {
        require(_newSigner != address(0), "Invalid signer");
        require(!isSigner[_newSigner], "Already a signer");

        isSigner[_newSigner] = true;
        signers.push(_newSigner);
        emit SignerAdded(_newSigner);
    }

    /**
     * @notice Removes a signer from the wallet
     * @param _signer Address of the signer to remove
     */
    function removeSigner(address _signer) public onlySigner {
        require(isSigner[_signer], "Not a signer");
        require(
            signers.length > MIN_SIGNERS,
            "Cannot go below minimum signers"
        );
        require(_signer != msg.sender, "Cannot remove yourself");

        isSigner[_signer] = false;

        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == _signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                emit SignerRemoved(_signer);
                break;
            }
        }
    }

    /**
     * @notice Executes a confirmed transaction
     * @param _txIndex Index of the transaction
     */
    function executeTransaction(
        uint256 _txIndex
    ) private txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        require(
            transaction.numConfirmations >= REQUIRED_CONFIRMATIONS,
            "Not enough confirmations"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Transaction failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /**
     * @notice Gets the list of signers
     * @return Array of signer addresses
     */
    function getSigners() public view returns (address[] memory) {
        return signers;
    }

    /**
     * @notice Gets the transaction count
     * @return Number of transactions submitted
     */
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /**
     * @notice Gets a transaction's details
     * @param _txIndex Index of the transaction
     * @return to Address the transaction is directed to
     * @return value Amount of ETH being sent
     * @return data Transaction data payload
     * @return executed Whether the transaction has been executed
     * @return numConfirmations Number of confirmations received
     */
    function getTransaction(
        uint256 _txIndex
    )
        public
        view
        txExists(_txIndex)
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    receive() external payable {}
}
