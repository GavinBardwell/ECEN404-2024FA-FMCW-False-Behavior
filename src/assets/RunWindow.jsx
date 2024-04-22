import React, { useState, useEffect } from 'react';
import ScaleSelector from './ScaleSelector';
import RunDetailsChart from './RunVisualization'; // Adjust the import path if necessary
import RunsTable from './RunTable';
import ActiveRunTable from './ActiveRunTable';
import VariableAxisSelector from './VariableAxisSelector';
import './RunWindow.css'
import { Upload } from './Upload';

function RunWindow() {
  const [mockData, setMockData] = useState([])
  const [scales, setScales] = useState({ X: 'linear', Y: 'linear'});
  const [selectedRuns, setSelectedRuns] = useState({Runs: []});
  const [variableForAxis, setVariableForAxis] = useState({ X: '', Y: ''});
  const [chartData, setChartData] = useState({Runs: []})
  const [graphsToPlot, setGraphsToPlot] = useState([])
  const transformData = (totalSelectedRuns, X, Y) => {
    return {
      Runs: totalSelectedRuns.Runs.map(run => ({
        name: run.name,
        [X]: run[X],
        [Y]: run[Y]
      }))
    }
  }
  const handleFileUpload = jsonData => {
    try {
      const data = JSON.parse(jsonData);
      setMockData(data);  // Assuming the JSON data is in the correct format
    } catch (error) {
      alert('Failed to parse JSON data');
    }
  };
  const handleScaleChange = (axis, selectedScale) => {
    // Update the scales state with new values for either x or y
  setScales(prevScales => ({
    ...prevScales,
    [axis]: selectedScale,
  }),
  );
  }
  const handleVariableForAxisChange = (axis, selectedVariableForAxis) => {
    setVariableForAxis(prevVariableForAxis => {
      // Check if the other axis already has the same variable assigned
      const otherAxis = axis === 'X' ? 'Y' : 'X';
      if (prevVariableForAxis[otherAxis] === selectedVariableForAxis) {
        alert('Please choose a different variable for each axis.');
        return prevVariableForAxis; // Return previous state without changes
      }
      return {
        ...prevVariableForAxis,
        [axis]: selectedVariableForAxis,
      };
    });
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

  const addGraph = () => {
    setGraphsToPlot(graphs => [
      ...graphs,
      {
        xScale: scales.X,
        yScale: scales.Y,
        inputData: chartData,
        xKey: variableForAxis.X,
        yKey: variableForAxis.Y
      }
    ])
  }
  useEffect(() => {
    //comand picks only the selected X and Y axis from the selected runs
    if (selectedRuns.Runs.length > 0 && variableForAxis.X && variableForAxis.Y) {
      const transformedData = transformData(selectedRuns, variableForAxis.X, variableForAxis.Y)
      setChartData(transformedData)
    }
  }, [selectedRuns, variableForAxis]);

  useEffect(() => {
    //console.log(graphsToPlot);
    //console.log(mockData);
  }, [chartData, graphsToPlot])

  //takes in the index of the run to remove and then sets the graph to not include that
  const removeGraph = (indexToRemove) => {
    setGraphsToPlot(graphs => graphs.filter((_, index) => index !== indexToRemove));
  };

  return (
    
    <div className="run-container">
      {(mockData.length === 0) ? (<Upload onFileUpload={handleFileUpload} />) : (
      <div className = "DifferentSelections">
      <div className="Run-Box">
        <RunsTable inputRuns={mockData} selectedRuns={selectedRuns.Runs} onRunSelectionChange={handleRunSelectionChange}/>
      </div>
      <div className="active-Run-Box">
        {graphsToPlot.length !== 0 && <ActiveRunTable inputRuns={graphsToPlot} onRunRemoval={removeGraph}/>}
      </div>
      <div className='AxisSelectors'>
        <div className='X-selector'><ScaleSelector axis="X" onScaleChange={handleScaleChange} /> <VariableAxisSelector axis="X" currentRuns={mockData} onAxisVarChange={handleVariableForAxisChange}/></div>
        <div className='Y-selector'><ScaleSelector axis="Y" onScaleChange={handleScaleChange} /> <VariableAxisSelector axis="Y" currentRuns={mockData} onAxisVarChange={handleVariableForAxisChange}/></div>
      </div>
      <div className="Add graph"> {((chartData.Runs.length > 0) && (variableForAxis.X !== '' && variableForAxis.Y !== '')) ? 
      (        <button onClick={addGraph}>add graph</button>
      ) : (
        <p>select required data</p>
      )
      }
      </div>
      </div>
      )}
      <div className="graph-window">
      {graphsToPlot.map((graph, index) => (
          <RunDetailsChart key={index} xScale={graph.xScale} yScale={graph.yScale} inputData={graph.inputData} xKey={graph.xKey} yKey={graph.yKey} />
        ))}
      {graphsToPlot.length === 0 && <p className='graph-Container'>No graphs to display. Select data and add a graph.</p>}

      </div>
    </div>
  );
}

export default RunWindow;