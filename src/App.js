import './App.css';
import { useState } from 'react' /*used for updating the state of an object*/
import ReactDOM from 'react-dom';
import { BrowserRouter as Router, Routes, Route, BrowserRouter, createBrowserRouter, createRoutesFromElements } from "react-router-dom";
import Navbar from './assets/Navbar';
import RunOverview from './assets/Overview';
import RunWindow from './assets/RunWindow';
function App() {
  return (
    <div className="App">
      <RunWindow />

    </div>
  );
}
  /*      <Router>
        <Navbar/>
        <div className="App-window">
        <Routes>
          <Route index element={<RunOverview/>}></Route>
          <Route element={<RunWindow/>} path="Runs"></Route>
        </Routes>
        </div>
      </Router>*/ 
export default App;