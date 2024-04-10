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

const RunDetailsChart = ({ xScale = 'linear', yScale = 'linear', inputData }) => {
  const [data, setData] = useState([]);

  useEffect(() => {
    const transformData = (rawData) => {
        let transformed = [];
        for (let i = 0; i < rawData.Runs[0].power.length; i++) {
          let point = { time: i }; // Time in ms
          rawData.Runs.forEach(run => {
            point[`Run ${run.id}`] = run.power[i];
          });
          transformed.push(point);
        }
        return transformed;
      };
    const dataForChart = transformData(inputData, yScale);
    setData(dataForChart);
  }, [xScale, yScale, inputData]); // Updates whenever yScale changes

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
      <XAxis dataKey="time" scale={scaleType(xScale)} label={{ value: 'Time (ms)', position: 'insideBottomRight', offset: 0 }} />
      <YAxis scale={scaleType(yScale)} label={{ value: 'Power', angle: -90, position: 'insideLeft'}} domain={['auto', 'auto']} />
      <Tooltip />
      <Legend />
      {data[0] && Object.keys(data[0]).filter(key => key !== 'time').map((key, idx) => (
        <Line type="monotone" dataKey={key} stroke={colors[idx % colors.length]} key={idx} />
      ))}
    </LineChart>
  );
};

export default RunDetailsChart;