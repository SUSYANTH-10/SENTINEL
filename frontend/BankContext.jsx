import React, { useState, createContext, useContext } from 'react';

// 1. Create the Context
export const BankContext = createContext();

export const BankProvider = ({ children }) => {
  // 2. Initial Mock Database
  const [users, setUsers] = useState({
    'senior@upi': {
      id: 'senior@upi',
      name: 'Devraj Sharma (Senior)',
      password: '123',
      balance: 50000,
      ghostBalance: 1840,
      isDuressActive: false,
      history: [
        {
          id: 'TXN-902184',
          type: 'RECEIVE',
          amount: 45000,
          from: 'SBI Senior Pension Fund',
          timestamp: new Date(Date.now() - 86400000).toISOString()
        }
      ]
    },
    'daughter@upi': {
      id: 'daughter@upi',
      name: 'Priya Sharma (Daughter)',
      password: 'abc',
      balance: 10000,
      ghostBalance: 10000,
      isDuressActive: false,
      history: []
    },
    'scammer@upi': {
      id: 'scammer@upi',
      name: 'Unverified Mule (Police Safe Vault)',
      password: '000000',
      balance: 0,
      ghostBalance: 0,
      isDuressActive: false,
      history: []
    }
  });
  
  const [currentUserId, setCurrentUserId] = useState('senior@upi');
  const [activeEscrow, setActiveEscrow] = useState(null);

  // 3. The Core Transfer Function (Double-Entry + Dynamic Account Generation)
  const processTransfer = (recipientId, amount, note = '', isEscrow = false) => {
    const cleanRecipientId = (recipientId || 'unknown@upi').trim().toLowerCase();
    const numAmount = parseFloat(amount);
    if (!cleanRecipientId || isNaN(numAmount) || numAmount <= 0) return false;

    let success = false;

    setUsers(prevUsers => {
      const updatedUsers = { ...prevUsers };
      const sender = updatedUsers[currentUserId];

      if (!sender) return prevUsers;

      // Block if insufficient funds
      if (sender.balance < numAmount) {
        alert("Insufficient funds in account.");
        return prevUsers;
      }

      // Check if recipient exists. If not, CREATE them instantly.
      if (!updatedUsers[cleanRecipientId]) {
        const handlePart = cleanRecipientId.split('@')[0].replace(/[._-]/g, ' ');
        const cleanName = handlePart.charAt(0).toUpperCase() + handlePart.slice(1) + " (Payee)";

        updatedUsers[cleanRecipientId] = {
          id: cleanRecipientId,
          name: cleanName,
          password: '000000', // Default password as requested
          balance: 0,
          ghostBalance: 0,
          isDuressActive: false,
          history: []
        };
      }

      const txId = `TXN-${Math.floor(100000 + Math.random() * 900000)}`;
      const now = new Date().toISOString();

      if (isEscrow) {
        // Deduct from Sender and hold in Escrow buffer
        updatedUsers[currentUserId].balance -= numAmount;
        updatedUsers[currentUserId].history.unshift({
          id: txId,
          type: 'SEND',
          amount: numAmount,
          to: cleanRecipientId,
          timestamp: now,
          status: 'ESCROW_HOLDING',
          note: note || 'Safe Escrow Buffered'
        });

        setActiveEscrow({
          id: txId,
          amount: numAmount,
          beneficiary: updatedUsers[cleanRecipientId]?.name || cleanRecipientId,
          recipientVpa: cleanRecipientId,
          remainingSeconds: 1799,
          status: 'holding'
        });
      } else {
        // Deduct from Sender
        updatedUsers[currentUserId].balance -= numAmount;
        updatedUsers[currentUserId].history.unshift({
          id: txId,
          type: 'SEND',
          amount: numAmount,
          to: cleanRecipientId,
          timestamp: now,
          status: 'COMPLETED',
          note: note || 'Instant Transfer'
        });

        // Add to Recipient
        updatedUsers[cleanRecipientId].balance += numAmount;
        updatedUsers[cleanRecipientId].history.unshift({
          id: txId,
          type: 'RECEIVE',
          amount: numAmount,
          from: currentUserId,
          timestamp: now,
          status: 'COMPLETED',
          note: note || 'Received via SENTINEL'
        });
      }

      success = true;
      return updatedUsers;
    });

    return success;
  };

  // Reversal for Escrow cancellation
  const cancelEscrow = () => {
    if (!activeEscrow) return null;
    const refundAmount = activeEscrow.amount;
    const escrowId = activeEscrow.id;

    setUsers(prevUsers => {
      const updated = { ...prevUsers };
      const sender = updated[currentUserId];
      if (sender) {
        sender.balance += refundAmount;
        sender.history = sender.history.map(tx => {
          if (tx.id === escrowId) {
            return { ...tx, status: 'REVERSED', note: 'Cancelled & Immediately Refunded' };
          }
          return tx;
        });
      }
      return updated;
    });

    setActiveEscrow(null);
    return { amount: refundAmount, refId: escrowId };
  };

  return (
    <BankContext.Provider value={{
      users,
      currentUserId,
      setCurrentUserId,
      processTransfer,
      activeEscrow,
      setActiveEscrow,
      cancelEscrow
    }}>
      {children}
    </BankContext.Provider>
  );
};

export const useBank = () => useContext(BankContext);
