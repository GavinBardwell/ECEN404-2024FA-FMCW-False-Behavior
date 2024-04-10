import React, { useState } from 'react';
import ScaleSelector from './ScaleSelector';
import RunDetailsChart from './RunVisualization'; // Adjust the import path if necessary
import mockData from './RunDetails.json';
import RunsTable from './RunTable';

function RunWindow() {
  const [scales, setScales] = useState({ X: 'linear', Y: 'linear'});
  const [selectedRuns, setSelectedRuns] = useState({Runs: []});
  const handleScaleChange = (axis, selectedScale) => {
    // Update the scales state with new values for either x or y
    setScales(prevScales => ({
      ...prevScales,
      [axis]: selectedScale,
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
      <div>
        <ScaleSelector axis="X" onScaleChange={handleScaleChange} />
        <ScaleSelector axis="Y" onScaleChange={handleScaleChange} />
      </div>

      <header className="App-header">
      <p>
          Current Selected Run Info
        </p>
        {selectedRuns.Runs.length > 0 ? (
          <RunDetailsChart xScale={scales.X} yScale={scales.Y} inputData={selectedRuns}/>
        ) : (
          <p>No selected data</p>
        )}
      </header>
    </div>
  );
}

export default RunWindow;