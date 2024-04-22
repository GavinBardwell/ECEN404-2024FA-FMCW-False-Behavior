import React, { useState, useEffect } from 'react';
import mockData from './RunDetails.json';
import './Overview.css';
const RunOverview = () => {
  const [runData, setRunData] = useState([]);

  useEffect(() => {
    // Simulating fetching data from an API
    setRunData(mockData.Runs);
  }, []);

  return (
    <div className='Run-Box'>
      <div className='Run-Title'>Runs</div>
      <table className='Run-Table'>
        <th>ID</th>
        <th>Name</th>
        <th>Date</th>
        {runData.map(Run => (
          <tr>
          <td>{Run.id}</td> 
          <td>{Run.name}</td>
          <td>{Run.Date}</td>
          </tr>
        ))}
      </table>
    </div>
  );
};
export default RunOverview;