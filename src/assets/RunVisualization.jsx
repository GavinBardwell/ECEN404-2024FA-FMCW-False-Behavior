import React, { useEffect, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import mockData from './RunDetails.json';
import { scaleLog, scaleLinear } from 'd3-scale';


const scaleType = (type) => {
    switch (type) {
      case 'linear':
        return scaleLinear();
      case 'log':
        return scaleLog();
      case 'dB':
        // Assuming your data isn't already in dB. If it is, use 'linear' instead.
        return 'linear'; // You would need to transform your data to dB before plotting.
      default:
        return 'linear';
    }
  };


const RunDetailsChart = ({ xScale = 'linear', yScale = 'linear' }) => {
  const [data, setData] = useState([]);

  useEffect(() => {
    const transformData = (rawData) => {
        let transformed = [];
        // If yScale is 'dB', transform the data accordingly. Else, leave as is.
        const isDbScale = yScale === 'dB';
        for (let i = 0; i < rawData.Runs[0].power.length; i++) {
          let point = { time: i }; // Time in ms
          rawData.Runs.forEach(run => {
            point[`Run ${run.id}`] = isDbScale ? 10 * Math.log10(run.power[i]) : run.power[i];
          });
          transformed.push(point);
        }
        return transformed;
      };

    const dataForChart = transformData(mockData, yScale);
    setData(dataForChart);
    console.log(dataForChart)
  }, [xScale, yScale]); // Updates whenever yScale changes

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
        <Line type="monotone" dataKey={key} stroke={`#${Math.floor(Math.random()*16777215).toString(16)}`} key={idx} />
      ))}
    </LineChart>
  );
};

export default RunDetailsChart;