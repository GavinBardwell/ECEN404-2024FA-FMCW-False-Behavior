import React, { useState } from 'react';
import ScaleSelector from './ScaleSelector';
import RunDetailsChart from './RunVisualization'; // Adjust the import path if necessary


function RunWindow() {
  const [scales, setScales] = useState({ X: 'linear', Y: 'linear' });

  const handleScaleChange = (axis, selectedScale) => {
    // Update the scales state with new values for either x or y
    setScales(prevScales => ({
      ...prevScales,
      [axis]: selectedScale,
    }),
  );
  }
  return (
    
    <div className="App">
      <div>
        <ScaleSelector axis="X" onScaleChange={handleScaleChange} />
        <ScaleSelector axis="Y" onScaleChange={handleScaleChange} />
      </div>
      <header className="App-header">
        <p>
          Simple Recharts Example
        </p>
        <RunDetailsChart xScale={scales.X} yScale={scales.Y}/>
      </header>
    </div>
  );
}

export default RunWindow;