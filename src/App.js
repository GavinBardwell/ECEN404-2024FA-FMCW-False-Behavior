import './App.css';
import { useState } from 'react' /*used for updating the state of an object*/
import { BrowserRouter as Router, Routes, Route, BrowserRouter, createBrowserRouter, createRoutesFromElements } from "react-router-dom";
import Navbar from './Navbar';
function App() {
  return (
    <div className="App">
      <Router>
        <Navbar/>
        <Routes>
        <Route index element={<index />}></Route>
        </Routes>
      </Router>
      <header className="App-header">
        <p>hello world</p>
      </header>
    </div>
  );
}

export default App;
