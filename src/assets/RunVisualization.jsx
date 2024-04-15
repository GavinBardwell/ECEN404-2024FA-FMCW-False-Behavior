import React, { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import { scaleLog, scaleLinear } from 'd3-scale';


const scaleType = (type) => {
    switch (type) {
      case 'linear':
        return scaleLinear();
      case 'log':
        return scaleLog();
      default:
        return 'linear';
    }
  };
const colors = ['#8884d8', '#82ca9d', '#ffc658', '#ff7300', '#413ea0', '#1f77b4', '#d62728', '#2ca02c', '#9467bd', '#8c564b'];

const RunDetailsChart = ({ xScale = 'linear', yScale = 'linear', inputData, xKey, yKey }) => {
  const [data, setData] = useState([]);

  useEffect(() => {
    if (inputData && inputData.Runs) {
      // Map each run to its own series of data points
      console.log(inputData.Runs)
      console.log(Object.keys(inputData)[0])
      const newData = inputData.Runs.map((run, index) => ({
        data: run[xKey].map((x, i) => ({
          [xKey]: x,  // Dynamic xKey from the run
          [yKey]: run[yKey][i],  // Dynamic yKey from the same run
        })),
      }));
      //console.log(newData)
      setData(newData);
    }
  }, [inputData, xKey, yKey]);
  

  return (
   <LineChart
      width={800}
      height={400}
      data={data}
      margin={{
        top: 5,
        right: 30,
        left: 20,
        bottom: 5,
      }}
    >
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey={xKey} scale={scaleType(xScale)} label={{ value: 'Time (ms)', position: 'insideBottomRight', offset: 0 }} />
      <YAxis scale={scaleType(yScale)} label={{ value: 'Power', angle: -90, position: 'insideLeft'}} domain={['auto', 'auto']} />
      <Tooltip />
      <Legend />
      {data.map((run, idx) => (
  <Line
    type="monotone"
    data={run.data}  // Correctly assign data to each Line
    dataKey={yKey}   // Correctly point to the property in the data points
    stroke={colors[idx % colors.length]}
    key={idx}  // Adding a key for React's list rendering
  />
))}
    </LineChart>
  );
};

export default RunDetailsChart;