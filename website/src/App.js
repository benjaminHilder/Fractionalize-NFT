import { useState } from 'react';
import './App.css';
import NavBar from './NavBar';
import Main from './Main';

function App() {
  const [accounts, setAccounts] = useState([]);

  return (
    <div className="overlay">
    <div className="App">
    <NavBar accounts={accounts} setAccounts={setAccounts} />
    <Main accounts={accounts} setAccounts={setAccounts} />
    </div>
    <div className="moving-background"></div>
  </div>);
}

export default App;
