import os
import json
import logging
import numpy as np

logging.basicConfig(format="%(levelname)s | %(message)s", level = logging.INFO)

def processBinaryFiles(testName, cfg):

    # Open the binary file in the test directory
    try:
        os.rename("./Data/temp/data_Raw_0.bin", "./Data/{}/{}_rawBinary.bin".format(testName, testName))
        with open("./Data/{}/{}_rawBinary.bin".format(testName, testName), "rb") as f:
            data = np.fromfile(f, dtype = np.int16)
    except FileNotFoundError:
        logging.error("An error occurred while trying to access binary file in directory ./Data/temp/data")

    # Non-interleaved data follow the format RX1,0, RX1,1, RX1,2, RX1,3, RX2,0, RX2,1, RX2,2, RX2,3, ...
    # Interleaved data follow the format RX1,0, RX2,0, RX3,0, RX4,0, RX1,1, RX2,1, RX3,1, RX4,1, ...

    # Create our reshaped data array
    # This array will separate the data into rows depending on the RX antenna
    # So row 1 will correspond to RX1, row 2 to RX2, etc.

    if not cfg.interleaved:
        # Reshape the data
        chirpMajor = np.reshape(data, (cfg.numADCSamples * cfg.numRXAntennas, cfg.numChirps))
        reshaped = np.zeros((4, cfg.numChirps * cfg.numADCSamples))

        for row in range(0, cfg.numRXAntennas):
            for i in range(0, cfg.numChirps):
                reshaped[row, ((i) * cfg.numADCSamples):((i+1) * cfg.numADCSamples)] = chirpMajor[i, ((row) * cfg.numADCSamples):((row + 1) * cfg.numADCSamples)]

        # Save reshaped to a csvfile
        with open("./Data/{}/{}_RXSeperated.csv".format(testName, testName), "w") as f:
            np.savetxt(f, reshaped, delimiter = ",")
            logging.info("Saved processed and reshaped binary data to file: ./Data/{}/{}_RXSeperated.csv".format(testName, testName))

        return reshaped
    
    if cfg.interleaved:
        return -1


"""
def processBinaryFiles(testName, cfg):
    try:
        binaryFiles = []
        for file in os.listdir("./Data/temp"):
            if file.endswith(".bin"):
                binaryFiles.append(file)
        for binaryFile in binaryFiles:
            logging.info("Processing binary file: {}".format(binaryFile))
            data = reformatBinaryFiles("Data/test_{}/{}".format(testName, binaryFile), cfg)
        return data
    except FileNotFoundError:
        logging.error("Invalid test name (no such directory {}).".format("./Data/test_{}".format(testName)))
"""
