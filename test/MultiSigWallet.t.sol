// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    address[] public signers;

    address public signer1;
    address public signer2;
    address public signer3;
    address public nonSigner;

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

    function setUp() public {
        signer1 = vm.addr(1);
        signer2 = vm.addr(2);
        signer3 = vm.addr(3);
        nonSigner = vm.addr(4);

        signers = new address[](3);
        signers[0] = signer1;
        signers[1] = signer2;
        signers[2] = signer3;

        wallet = new MultiSigWallet(signers);

        // Fund the wallet
        vm.deal(address(wallet), 10 ether);
    }

    function testInitialState() public {
        assertTrue(wallet.isSigner(signer1));
        assertTrue(wallet.isSigner(signer2));
        assertTrue(wallet.isSigner(signer3));
        assertFalse(wallet.isSigner(nonSigner));

        address[] memory currentSigners = wallet.getSigners();
        assertEq(currentSigners.length, 3);
    }

    function testSubmitTransaction() public {
        address to = address(0x123);
        uint256 value = 1 ether;
        bytes memory data = "";

        vm.prank(signer1);
        vm.expectEmit(true, true, true, true);
        emit SubmitTransaction(signer1, 0, to, value, data);
        uint256 txIndex = wallet.submitTransaction(to, value, data);

        (
            address txTo,
            uint256 txValue,
            bytes memory txData,
            bool executed,
            uint256 numConfirmations
        ) = wallet.getTransaction(txIndex);

        assertEq(txTo, to);
        assertEq(txValue, value);
        assertEq(txData, data);
        assertFalse(executed);
        assertEq(numConfirmations, 0);
    }

    function testFailSubmitTransactionNonSigner() public {
        vm.prank(nonSigner);
        wallet.submitTransaction(address(0x123), 1 ether, "");
    }

    function testConfirmTransaction() public {
        address to = address(0x123);
        uint256 value = 1 ether;
        bytes memory data = "";

        vm.prank(signer1);
        uint256 txIndex = wallet.submitTransaction(to, value, data);

        vm.prank(signer2);
        vm.expectEmit(true, true, false, true);
        emit ConfirmTransaction(signer2, txIndex);
        wallet.confirmTransaction(txIndex);

        (, , , , uint256 numConfirmations) = wallet.getTransaction(txIndex);
        assertEq(numConfirmations, 1);
    }

    function testRevokeConfirmation() public {
        address to = address(0x123);
        uint256 value = 1 ether;
        bytes memory data = "";

        vm.prank(signer1);
        uint256 txIndex = wallet.submitTransaction(to, value, data);

        vm.prank(signer2);
        wallet.confirmTransaction(txIndex);

        vm.prank(signer2);
        vm.expectEmit(true, true, false, true);
        emit RevokeConfirmation(signer2, txIndex);
        wallet.revokeConfirmation(txIndex);

        (, , , , uint256 numConfirmations) = wallet.getTransaction(txIndex);
        assertEq(numConfirmations, 0);
    }

    function testExecuteTransaction() public {
        address payable to = payable(address(0x123));
        uint256 value = 1 ether;
        bytes memory data = "";

        // Submit transaction
        vm.prank(signer1);
        uint256 txIndex = wallet.submitTransaction(to, value, data);

        // First confirmation
        vm.prank(signer2);
        wallet.confirmTransaction(txIndex);

        // Second confirmation and execution
        vm.prank(signer3);
        vm.expectEmit(true, true, false, true);
        emit ExecuteTransaction(signer3, txIndex);
        wallet.confirmTransaction(txIndex);

        // Verify execution
        (, , , bool executed, ) = wallet.getTransaction(txIndex);
        assertTrue(executed);
        assertEq(to.balance, value);
    }

    function testAddSigner() public {
        address newSigner = address(0x456);

        vm.prank(signer1);
        vm.expectEmit(true, false, false, true);
        emit SignerAdded(newSigner);
        wallet.addSigner(newSigner);

        assertTrue(wallet.isSigner(newSigner));
        address[] memory currentSigners = wallet.getSigners();
        assertEq(currentSigners.length, 4);
    }

    function testRemoveSigner() public {
        // First, we add a new signer to get 4 signers
        vm.prank(signer1);
        address newSigner = address(0x456);
        wallet.addSigner(newSigner);

        // Now we can remove a signer
        vm.prank(signer1);
        vm.expectEmit(true, false, false, true);
        emit SignerRemoved(signer3);
        wallet.removeSigner(signer3);

        assertFalse(wallet.isSigner(signer3));
        address[] memory currentSigners = wallet.getSigners();
        assertEq(currentSigners.length, 3);
    }

    function testFailRemoveSignerBelowMinimum() public {
        // Remove signer3
        vm.prank(signer1);
        wallet.removeSigner(signer3);

        // Try to remove signer2, which would bring us below minimum
        vm.prank(signer1);
        wallet.removeSigner(signer2);
    }

    function testFailConstructorBelowMinSigners() public {
        address[] memory insufficientSigners = new address[](2);
        insufficientSigners[0] = signer1;
        insufficientSigners[1] = signer2;

        new MultiSigWallet(insufficientSigners);
    }

    receive() external payable {}
}
