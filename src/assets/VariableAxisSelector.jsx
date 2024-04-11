import React, { useState, useEffect } from 'react';

function VariableAxisSelector({ axis, currentRuns, onAxisVarChange }) {
  // Assume the structure of currentRuns objects is consistent
  // and use the keys from the first run to generate the options.
  const [selectedVar, setSelectedVar] = useState('power');
  
  // Assuming all runs have the same structure,
  // extract the keys from the first run to use as options.
  const variableOptions = currentRuns.Runs.length > 0
    ? Object.keys(currentRuns.Runs[0]).filter(key => key !== 'id' && key !== 'name' && key !== 'Date')
    : [];

  useEffect(() => {
    // Initialize with the first available variable, if not set
    if (variableOptions.length > 0 && !selectedVar) {
      setSelectedVar(variableOptions[0]);
    }
  }, [variableOptions, selectedVar]);

  const handleChange = (event) => {
    const newVar = event.target.value;
    setSelectedVar(newVar);
    onAxisVarChange(axis, newVar);
  };

  return (
    <div>
      <label htmlFor={`variable-select-${axis}`}>{`Select variable for ${axis} axis: `}</label>
      <select id={`variable-select-${axis}`} value={selectedVar} onChange={handleChange}>
        <option key='time' value='time'>time</option>
        {variableOptions.map((option) => (
          <option key={option} value={option}>{option}</option>
        ))}
      </select>
    </div>
  );
}

export default VariableAxisSelector;