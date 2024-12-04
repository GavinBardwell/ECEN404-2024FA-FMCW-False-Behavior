import os 
import json
import logging

logging.basicConfig(format="%(levelname)s | %(message)s", level = logging.INFO)

import numpy as np
import binaryRead
import calculations
import interpretConfig

def main():
    print("- - - DCA1000EVM Data Collection & Analysis | Written by Brody Jordan for use in ECEN-403  - - -")
    
    # Read configuration file
    configuration = interpretConfig.configuration()

    while True:
        testName = input("Enter test name: ")

        # Clear the temp directory
        #for file in os.listdir("./Data/temp"):
        #    os.remove("./Data/temp/{}".format(file))

        # Create test directory if it doesn't exist
        if not os.path.exists("./Data/{}".format(testName)):
            os.makedirs("./Data/{}".format(testName))
            logging.info("Directory successfully created.")

            trigger = input("Trigger DCA1000EVM and press ENTER to continue.")

            processedData = binaryRead.processBinaryFiles(testName, configuration)

            # Determine what type of processing to do
            processType = input("1. Range profile \n2. Doppler profile \n3. Both \n4. Exit \nEnter a number (1 - 4): ")
            match processType:
                case "3":
                    rangeResults = calculations.calculateRange(testName, processedData, configuration)
                    dopperResults = calculations.calculateDopper(testName, processedData, configuration)
                case "1":
                    rangeResults = calculations.calculateRange(testName, processedData, configuration)
                case "2":
                    dopperResults = calculations.calculateDopper(testName, processedData, configuration)
                case "4":
                    break
                case _: 
                    logging.warning("Invalid input. Please enter a number between 1 and 4.")

        # If the test directory already exists, prompt the user to enter a different name
        else:
            logging.warning("Directory already exists. Please enter a different name.")

if __name__ == "__main__":
    main()


    



