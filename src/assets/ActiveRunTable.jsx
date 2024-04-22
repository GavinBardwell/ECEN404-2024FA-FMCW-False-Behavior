import React, { useState, useEffect } from 'react';
import "./RunTable.css"
const ActiveRunTable = ({ inputRuns,  onRunRemoval }) => {
  const [runData, setRunData] = useState([])
  useEffect(() => {
    // Simulating fetching data from an API
    console.log(inputRuns)
    setRunData(inputRuns);
  }, [inputRuns]);

  // Assuming you'll use the selectedRuns for data visualization elsewhere
  // You might pass setSelectedRuns to a context, or lift state up to use it in other components

  return (
    <table className='Run-Table'>
      <thead>
        <tr>
          <th>Runs</th>
          <th>X axis</th>
          <th>Y Axis</th>
          <th>Remove</th>
        </tr>
      </thead>
      <tbody>
        {runData.map((graph, index) => (
          <tr key={`${graph.id}`}>
            <td>{graph.inputData.Runs.map(detail => detail.name).join(', ')}</td>
            <td>{graph.xKey}</td>
            <td>{graph.yKey}</td>
            <td>
            <button onClick={() => onRunRemoval(index)}>X</button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};

export default ActiveRunTable;