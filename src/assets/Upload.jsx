import React, { useState } from "react";

export function Upload({ onFileUpload }) {
  const [loading, setLoading] = useState(false);

  const handleChange = e => {
    const file = e.target.files[0];
    if (file && file.type === "application/json") {
      const fileReader = new FileReader();
      fileReader.readAsText(file, "UTF-8");
      setLoading(true);
      fileReader.onload = e => {
        setLoading(false);
        onFileUpload(e.target.result);  // Pass the loaded data up
      };
      fileReader.onerror = () => {
        setLoading(false);
        alert("Error reading file");
      };
    } else {
      alert("Please upload a valid JSON file.");
    }
  };

  return (
    <>
      <p>Upload JSON File</p>
      <input type="file" accept=".json,application/json" onChange={handleChange} />
      {loading && <p>Loading...</p>}
    </>
  );
}