import React, { useState } from 'react';
import { useBank } from './BankContext';

export const TransferScreen = () => {
  const { users, currentUserId, processTransfer, setCurrentUserId } = useBank();
  const [recipient, setRecipient] = useState('');
  const [amount, setAmount] = useState('');

  const currentUser = users[currentUserId] || { id: 'unknown', balance: 0, history: [] };

  const handleSend = () => {
    if (!recipient || !amount) {
      alert("Please enter both recipient UPI ID and amount.");
      return;
    }
    const success = processTransfer(recipient, amount);
    if (success) {
      alert(`Successfully sent ₹${amount} to ${recipient}`);
      setRecipient('');
      setAmount('');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6 flex flex-col items-center font-sans text-gray-900">
      
      {/* Balance Card */}
      <div className="bg-white p-6 rounded-2xl shadow-sm w-full max-w-md border border-gray-100 mb-6">
        <p className="text-gray-500 text-sm mb-1">Available Balance</p>
        <h1 className="text-4xl font-bold text-gray-900">₹{currentUser.balance.toLocaleString('en-IN')}</h1>
        <p className="text-xs text-gray-400 mt-2">Logged in as: <strong className="text-gray-700">{currentUser.id}</strong> ({currentUser.name || currentUser.id})</p>
      </div>

      {/* Transfer Form */}
      <div className="w-full max-w-md space-y-4">
        <input 
          type="text" 
          placeholder="Enter UPI ID (e.g., scammer@upi or judge1@upi)" 
          className="w-full p-4 rounded-xl border border-gray-200 text-lg focus:ring-2 focus:ring-blue-500 outline-none transition-all"
          value={recipient}
          onChange={(e) => setRecipient(e.target.value)}
        />
        
        <input 
          type="number" 
          placeholder="Amount (₹)" 
          className="w-full p-4 rounded-xl border border-gray-200 text-lg focus:ring-2 focus:ring-blue-500 outline-none transition-all"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />

        {/* TACTILE BUTTON: Note the active:scale-[0.97] and transition classes */}
        <button 
          onClick={handleSend}
          className="w-full bg-blue-600 text-white font-semibold text-lg p-4 rounded-xl shadow-md 
                     hover:bg-blue-700 hover:shadow-lg 
                     active:scale-[0.97] active:bg-blue-800 
                     transition-all duration-150 ease-out"
        >
          Send Money Securely
        </button>
      </div>

      {/* Demo Switcher for the Judges */}
      <div className="mt-12 p-4 bg-gray-100 rounded-xl w-full max-w-md">
        <h3 className="text-sm font-bold text-gray-700 mb-2">Hackathon Demo Switcher</h3>
        <p className="text-xs text-gray-500 mb-3">Switch accounts to prove the money arrived.</p>
        <select 
          className="w-full p-2.5 rounded-lg border border-gray-300 bg-white font-semibold text-gray-800 text-sm focus:ring-2 focus:ring-blue-500 outline-none"
          value={currentUserId}
          onChange={(e) => setCurrentUserId(e.target.value)}
        >
          {Object.keys(users).map(id => (
            <option key={id} value={id}>
              {id} (Bal: ₹{users[id].balance.toLocaleString('en-IN')})
            </option>
          ))}
        </select>
      </div>

      {/* Recent Ledger Records for Active Profile */}
      <div className="mt-6 w-full max-w-md bg-white p-4 rounded-2xl border border-gray-100 shadow-sm space-y-3">
        <h4 className="text-xs font-bold text-gray-500 uppercase tracking-wider">Account Transaction History</h4>
        <div className="space-y-2">
          {currentUser.history && currentUser.history.length > 0 ? (
            currentUser.history.map(tx => (
              <div key={tx.id || Math.random()} className="p-2.5 rounded-lg bg-gray-50 flex items-center justify-between text-xs">
                <div>
                  <span className={`inline-block px-1.5 py-0.5 rounded text-[10px] font-bold mr-2 ${tx.type === 'RECEIVE' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                    {tx.type}
                  </span>
                  <span className="font-semibold text-gray-800">{tx.type === 'RECEIVE' ? tx.from : tx.to}</span>
                </div>
                <div className={`font-bold ${tx.type === 'RECEIVE' ? 'text-green-600' : 'text-gray-900'}`}>
                  {tx.type === 'RECEIVE' ? '+' : '-'}₹{tx.amount.toLocaleString('en-IN')}
                </div>
              </div>
            ))
          ) : (
            <p className="text-xs text-gray-400 text-center py-2">No transactions recorded yet.</p>
          )}
        </div>
      </div>

    </div>
  );
};
