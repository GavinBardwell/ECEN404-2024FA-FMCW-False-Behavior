import React, { useState, useEffect } from 'react';
import ScaleSelector from './ScaleSelector';
import RunDetailsChart from './RunVisualization'; // Adjust the import path if necessary
import mockData from './RunDetails.json';
import RunsTable from './RunTable';
import VariableAxisSelector from './VariableAxisSelector';


const transformData = (rawData) => {
  let transformed = [];
  if (rawData.Runs.length === 0) return transformed; // Early return if no runs are selected

  for (let i = 0; i < rawData.Runs[0].power.length; i++) {
    let point = { time: i }; // Assuming time in ms
    rawData.Runs.forEach(run => {
      point[`Run ${run.id}`] = run.power[i];
    });
    transformed.push(point);
  }
  return transformed;
};

function RunWindow() {
  const [scales, setScales] = useState({ X: 'linear', Y: 'linear'});
  const [selectedRuns, setSelectedRuns] = useState({Runs: []});
  const [variableForAxis, setVariableForAxis] = useState({ X: 'time', Y: ''});
  const [chartData, setChartData] = useState([]);

  useEffect(() => {
    const transformed = transformData(selectedRuns);
    setChartData(transformed);
  }, [selectedRuns]);

  const handleScaleChange = (axis, selectedScale) => {
    // Update the scales state with new values for either x or y
  setScales(prevScales => ({
    ...prevScales,
    [axis]: selectedScale,
  }),
  );
  }
  const handleVariableForAxisChange = (axis, selectedVariableForAxis) => {
  setVariableForAxis(prevVariableForAxis => ({
    ...prevVariableForAxis,
    [axis]: selectedVariableForAxis,
  }),
  );
  }

  const handleRunSelectionChange = (run) => {
    setSelectedRuns(prev => {
      const isAlreadySelected = prev.Runs.some(r => r.id === run.id);
      if (isAlreadySelected) {
        return {
          ...prev,
          Runs: prev.Runs.filter(r => r.id !== run.id) // Deselect
        };
      } else {
        return {
          ...prev,
          Runs: [...prev.Runs, run] // Select
        };
      }
    });
  };
  return (
    
    <div className="App">
      <div>
        <RunsTable inputRuns={mockData} selectedRuns={selectedRuns.Runs} onRunSelectionChange={handleRunSelectionChange}/>
      </div>
      <div className='Selectors'>
        <div className='axis-selector'><ScaleSelector axis="X" onScaleChange={handleScaleChange} /> <VariableAxisSelector axis="X" currentRuns={mockData} onAxisVarChange={handleVariableForAxisChange}/></div>
        <div className='axis-selector'><ScaleSelector axis="Y" onScaleChange={handleScaleChange} /> <VariableAxisSelector axis="Y" currentRuns={mockData} onAxisVarChange={handleVariableForAxisChange}/></div>
      </div>

      <header className="App-header">
      <p>
          Current Selected Run Info
        </p>
        {selectedRuns.Runs.length > 0 ? (
          <RunDetailsChart xScale={scales.X} yScale={scales.Y} inputData={chartData}/>
        ) : (
          <p>No selected data</p>
        )}
      </header>
    </div>
  );
}

export default RunWindow;