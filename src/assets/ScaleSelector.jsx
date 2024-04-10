import React, { useState } from 'react';

function ScaleSelector({ axis, onScaleChange }) {
  // Initial state is set to 'linear' for both axes
  const [scale, setScale] = useState('linear');

  const handleChange = (event) => {
    const newScale = event.target.value;
    setScale(newScale);
    onScaleChange(axis, newScale);
  };

  return (
    <div>
      <label htmlFor={`scale-select-${axis}`}>axis {axis}: </label>
      <select id={`scale-select-${axis}`} value={scale} onChange={handleChange}>
        <option value="log">Log</option>
        <option value="linear">Linear</option>
      </select>
    </div>
  );
}

export default ScaleSelector;