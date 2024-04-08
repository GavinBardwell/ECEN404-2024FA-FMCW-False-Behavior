import './App.css';
import { useState } from 'react' /*used for updating the state of an object*/
import ReactDOM from 'react-dom';
import { BrowserRouter as Router, Routes, Route, BrowserRouter, createBrowserRouter, createRoutesFromElements } from "react-router-dom";
import Navbar from './assets/Navbar';
import RunOverview from './assets/Overview';
function App() {
  return (
    <div className="App">
      <Router>
        <Navbar/>
        <div className="App-window">
        <Routes>
          <Route index element={<RunOverview/>}></Route>
        </Routes>
        </div>
      </Router>
    </div>
  );
}

export default App;