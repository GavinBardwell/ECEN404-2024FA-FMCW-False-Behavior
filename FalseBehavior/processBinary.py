import numpy as np

# NUM_SAMPLES = 256 # ADC samples per chirp (should always be 256)

# num_RX = 4 # Number of RX antennas (should almost always be 4)

# Read raw radar binary from file
# Input: fileName
# Output: array of radar data sorted by RX antenna

def process_binary(fileName, num_RX=4, NUM_SAMPLES=256):
    raw_adc_data = np.fromfile(fileName, dtype=np.int16)

    num_chirps = raw_adc_data.size // (NUM_SAMPLES * num_RX)

    # Reshape into MATLAB-like structure that im familiar with
    adc_data_reshaped = raw_adc_data.reshape((num_chirps, NUM_SAMPLES * num_RX), order='C')
    adc_data_reshaped = adc_data_reshaped.reshape((num_chirps, NUM_SAMPLES * num_RX), order='C')

    # Separate RX data
    adc_data_final = np.zeros((num_RX, num_chirps * NUM_SAMPLES), dtype=np.int16)

    for row in range(num_RX):
        for i in range(num_chirps):
            adc_data_final[row, i * NUM_SAMPLES:(i + 1) * NUM_SAMPLES] = adc_data_reshaped[i, row * NUM_SAMPLES:(row + 1) * NUM_SAMPLES]

    # Return receiver data
    return adc_data_final
