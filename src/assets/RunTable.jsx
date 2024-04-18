import React, { useState, useEffect } from 'react';
import "./RunTable.css"
const RunsTable = ({ inputRuns, selectedRuns, onRunSelectionChange }) => {
  const [runData, setRunData] = useState([])
  useEffect(() => {
    // Simulating fetching data from an API
    setRunData(inputRuns.Runs);
  }, [inputRuns]);

  // Assuming you'll use the selectedRuns for data visualization elsewhere
  // You might pass setSelectedRuns to a context, or lift state up to use it in other components

  return (
    <table className='Run-Table'>
      <thead>
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Date</th>
          <th>Include</th>
        </tr>
      </thead>
      <tbody>
        {runData.map((run) => (
          <tr key={run.id}>

            <td>{run.id}</td>
            <td>{run.name}</td>
            <td>{run.Date}</td>
            <td>
              <input
                type="checkbox"
                checked={selectedRuns.some(r => r.id === run.id)}
                onChange={() => {onRunSelectionChange(run)
              }}
              />
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default RunsTable;