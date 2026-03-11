import React, { useState, useEffect } from 'react';

function App() {
  const [apiStatus, setApiStatus] = useState('checking...');
  const [items, setItems] = useState([]);
  const [newItem, setNewItem] = useState('');

  // fetch health check from backend
  useEffect(() => {
    fetch('/app/api/health')
      .then(res => res.json())
      .then(data => setApiStatus(data.status))
      .catch(() => setApiStatus('unreachable'));
  }, []);

  // fetch items
  useEffect(() => {
    fetch('/app/api/items')
      .then(res => res.json())
      .then(data => setItems(data))
      .catch(err => console.error('Failed to load items:', err));
  }, []);

  const addItem = () => {
    if (!newItem.trim()) return;
    fetch('/app/api/items', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: newItem })
    })
      .then(res => res.json())
      .then(item => {
        setItems([item, ...items]);
        setNewItem('');
      })
      .catch(err => console.error('Error adding item:', err));
  };

  return (
    <div style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
      <h1>MERN Stack Application</h1>
      <p>Backend API status: <strong>{apiStatus}</strong></p>
      
      <hr />
      
      <h2>Items</h2>
      <div>
        <input
          type="text"
          value={newItem}
          onChange={e => setNewItem(e.target.value)}
          placeholder="Enter item name"
          style={{ padding: '0.5rem', marginRight: '0.5rem' }}
        />
        <button onClick={addItem} style={{ padding: '0.5rem 1rem' }}>
          Add Item
        </button>
      </div>
      
      <ul style={{ marginTop: '1rem' }}>
        {items.map(item => (
          <li key={item._id}>{item.name}</li>
        ))}
      </ul>
    </div>
  );
}

export default App;
