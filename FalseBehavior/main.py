import sys
import os
import interpretConfig
import processBinary
import calculations
import falseBehavior

from scipy.constants import c as C
import numpy as np

import matplotlib.pyplot as plt
import matplotlib.animation as animation
import matplotlib

# Only call function if script is run directly, and take arguments
if __name__ == "__main__":

    # To see detection metrics, set DEV_MODE to True
    DEV_MODE = False

    # Check if there are two arguments
    if len(sys.argv) != 3:
        print("Usage: python3 main.py <config file> <data file>")
        sys.exit(1)

    # Get the arguments
    configFile = str(sys.argv[1])
    dataFile = str(sys.argv[2])
    
    # Process the configuration file
    print(f"Processing config file: '{configFile}'...")
    # Check if config file exists
    if not os.path.exists(configFile):
        print(f"Config file '{configFile}' does not exist.")
        sys.exit(1)
    try:
        configuration = interpretConfig.configuration(configFile)
        configuration.interpret()
    except Exception as e:
        print(f"Error processing config file: {e}")
        sys.exit(1)

    if configuration.interleaved == True:
        print("Interleaved data is not supported.")
        sys.exit(1)

    # Process the data file
    print(f"Processing data file: '{dataFile}'...")
    # Check if data file exists
    if not os.path.exists(dataFile):
        print(f"Data file '{dataFile}' does not exist.")
        sys.exit(1)
    try:
        RX_separated_data = processBinary.process_binary(dataFile, configuration.numRXAntennas, configuration.numADCSamples)
    except Exception as e:
        print(f"Error processing data file: {e}")
        sys.exit(1)

    # Now perform the calculations
    print("Performing calculations...")
    try:
        RX_fft = calculations.fft(RX_separated_data, configuration.numRXAntennas, configuration.numADCSamples)
    except Exception as e:
        print(f"Error performing calculations: {e}")
        sys.exit(1)

    # Calculate range bins
    chirpBW = (configuration.numADCSamples * configuration.freqSlope * 1e12) / (configuration.sampleRate * 2e3)
    rangeResolution = C / (2 * chirpBW)
    rangeBins = np.arange(configuration.numADCSamples / 2) * rangeResolution / 2

    # Scaling the FFT output to dBFS
    bits_factor = 2 ** (16 - 1)
    correcting_term = 20 * np.log10(float(bits_factor))
    correction_factor = correcting_term + 20 * np.log10(np.sum(np.hanning(configuration.numADCSamples))) - 20 * np.log10(np.sqrt(2))

    # Looking at antenna 0 in this case
    interest_data = [RX_fft[0, i] for i in range(0, configuration.numChirps, configuration.numChirpsPerFrame)]
    return_signal_dBFS_initials = 20 * np.log10(np.abs(interest_data)) - correction_factor

    minimum = np.min(return_signal_dBFS_initials)
    maximum = np.max(return_signal_dBFS_initials)
    threshold = falseBehavior.threshold_calculation(20 * np.log10(np.abs(RX_fft)) - correction_factor)
    
    print(f"Threshold: {threshold:.4f}")
    print("Generating animation...")

    matplotlib.use('Agg')

    # Create a figure and axis
    fig, ax = plt.subplots()
    line, = ax.plot([], [])
    text = ax.text(0.02, 0.74, '', transform=ax.transAxes)

    # Initialize the plot
    def init():
        ax.set_xlim(min(rangeBins), max(rangeBins))
        ax.set_ylim(-130, 0)
        ax.set_xlabel('Range (m)')
        ax.set_ylabel('Amplitude (dBFS)')
        ax.set_title('Inteference Validation Test')
        ax.grid(True)
        line.set_data([], [])
        text.set_text('')
        return line,

    # Update the plot for each frame
    def update(frame):
        y_data = return_signal_dBFS_initials[frame][0:128]
        x_data = rangeBins  # Generate x values based on the length of y_data

        # detection = falseBehavior.detect_false_behavior(y_data, peak_average_threshold=threshold)

        is_false_behavior, dev_metrics = falseBehavior.detect_false_behavior(y_data, peak_average_threshold=threshold)

        line.set_data(x_data, y_data)  # Update the line with the new data
        line.set_color('r' if is_false_behavior else 'b')

        if DEV_MODE:
            # text.set_text(f'Frame {frame + 1}/200 \n Peak: {detection[1]:.2f} \n Mean: {detection[2]:.2f} \n Peak-to-Average: {detection[3]:.5f} \n Peak-to-StdDev: {detection[4]:.2f} \n StdDev: {detection[5]:.2f} \n Skewness: {detection[6]:.2f}')
            text.set_text(
                f"Frame {frame + 1}/200 \n"
                f"Peak: {dev_metrics['peak']:.2f} \n"
                f"Mean: {dev_metrics['mean']:.2f} \n"
                f"RMS: {dev_metrics['rms']:.2f} \n"
                f"Peak-to-Average: {dev_metrics['peak_to_average']:.5f} \n"
                f"StdDev: {dev_metrics['std_dev']:.2f} \n"
                f"Skewness: {dev_metrics['skewness']:.2f}"
            )

        return line, text

    # Create the animation
    anim = animation.FuncAnimation(fig, update, frames=len(return_signal_dBFS_initials), init_func=init, blit=True, interval=1000)

    # Ask user how long the animation should be (12 seconds is the default)
    time = 200 / int(input("Animation duration (in seconds): ")) if DEV_MODE else 200 / 12
    anim.save('animation.mp4', writer='ffmpeg', fps=time, dpi=300)

    print("Animation saved as 'animation.mp4'")

    # Look through each 200 frames (each with 128 chirps) and determine how many chirps have false behavior per frame

    matplotlib.use('TkAgg')

    threshold = falseBehavior.threshold_calculation(20 * np.log10(np.abs(RX_fft)) - correction_factor)

    false_behavior_chirps = np.zeros((1, RX_fft.shape[1]))

    for chirp in range(RX_fft.shape[1]):
        false_behavior_chirps[0, chirp] = falseBehavior.detect_false_behavior(20*np.log10(np.abs(RX_fft[0, chirp, :])), peak_average_threshold=threshold)[0]

    # Loop over the false_behavior_chirps array 128 elements at a time and determine how many chirps have false behavior per frame
    false_behavior_frames = np.zeros((1, RX_fft.shape[1] // 128))

    for frame in range(RX_fft.shape[1] // 128):
        false_behavior_frames[0, frame] = np.sum(false_behavior_chirps[0, frame * 128:(frame + 1) * 128]) / 128 * 100

    # Plot the number of chirps with false behavior per frame as bar chart
    plt.plot(false_behavior_frames[0, :])
    plt.title('Percentage of Chirps with False Behavior per Frame')
    plt.xlabel('Frame')
    plt.ylabel('Percentage of Chirps with False Behavior')
    plt.show()








