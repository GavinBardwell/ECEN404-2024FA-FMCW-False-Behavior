import React, { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
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

const RunDetailsChart = ({ xScale = 'linear', yScale = 'linear', inputData }) => {
  const [data, setData] = useState([]);
  const [xKey, setXKey] = useState('');
  const [yKey, setYKey] = useState('');

  useEffect(() => {
    //sets the axis names to use... better than feeding it in because this way you know for sure that it is there
    setXKey(Object.keys((inputData.Runs)[0])[1])//name is 0, x is 1, y is 2
    setYKey(Object.keys((inputData.Runs)[0])[2])
    if (inputData.Runs) {
      // Map each run to its own series of data points
      const newData = inputData.Runs.flatMap((run, i) => ({
        name: run.name,
        data: run[Object.keys((inputData.Runs)[0])[1]].map((x, i) => ({
          [Object.keys((inputData.Runs)[0])[1]]: x,  // Dynamic xKey from the run
          [Object.keys((inputData.Runs)[0])[2]]: run[Object.keys((inputData.Runs)[0])[2]][i],  // Dynamic yKey from the same run
        }))
      }));
      setData(newData);
    }
  }, [inputData]);

  useEffect(() => {
    //console.log(data)
  }, [data])

  return (
    <ResponsiveContainer width="100%" height="100%">
   <LineChart data={data}>
        <text x={500 / 2} y={20} fill="black" textAnchor="middle" dominantBaseline="central">
            <tspan fontSize="14">{xKey} vs {yKey}</tspan>
        </text>
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey={xKey} scale={scaleType(xScale)} domain={['dataMin', 'dataMax']} />
      <YAxis dataKey={yKey} scale={scaleType(yScale)} label={{ value: [yKey], angle: -90, position: 'insideLeft'}} domain={['dataMin', 'dataMax']} />
      <Tooltip />
      <Legend />
      {data.map((run, idx) => (
        <Line
          type="monotone"
          data={run.data}  // Correctly assign data to each Line
          dataKey={yKey}   // Correctly point to the property in the data points
          stroke={colors[idx % colors.length]}
          key={run.name}  // Adding a key for React's list rendering
          name = {run.name}
        />
      ))}
    </LineChart>
    </ResponsiveContainer>
  );
};
export default RunDetailsChart;