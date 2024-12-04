import logging
import numpy as np
import matplotlib.pyplot as plt
from scipy import constants

logging.basicConfig(format="%(levelname)s | %(message)s", level = logging.INFO)

# Speed of light in m/s necessary for binning
C = constants.c 

def calculateRange(testName, processedData, cfg):
    # Hanning window to improve FFT results
    hanningWindow = np.hanning(cfg.numADCSamples)

    # Grab a chirp to check, choose RX1 for no reason in particular
    chirp = processedData[0][0:cfg.numADCSamples]

    # Perform FFT on the processed data chirp
    chirpFFT = np.fft.fft(chirp * hanningWindow, cfg.numADCSamples)
    # Half the results to remove mirrored values (conj. symmetry)
    chirpFFTHalved = np.abs(chirpFFT[:np.size(chirpFFT) // 2])

    # Scale the FFT results to dB
    chirpFFTScaled = 20 * np.log10(np.abs(chirpFFT))
    chirpFFTScaledHalved = chirpFFTScaled[:np.size(chirpFFTScaled) // 2]

    # Calculate the range bins
    chirpBW = (cfg.numADCSamples * cfg.freqSlope * 1e12) / (cfg.sampleRate * 2e3)
    rangeResolution = C / (2 * chirpBW)
    rangeBins = np.arange(cfg.numADCSamples / 2) * rangeResolution / 2

    # Plot the results to verify
    figure, axes = plt.subplots(2, 2)

    axes[0, 0].plot(range(cfg.numADCSamples), hanningWindow)
    axes[0, 0].set_title("Hanning Window (N=256)")
    axes[0, 0].set_xlabel("Sample")
    axes[0, 0].set_ylabel("Amplitude")

    axes[0, 1].plot(range(cfg.numADCSamples), chirp)
    axes[0, 1].set_title("Chirp Signal")
    axes[0, 1].set_xlabel("Sample")
    axes[0, 1].set_ylabel("ADC Reading")

    axes[1, 0].plot(rangeBins, chirpFFTHalved)
    axes[1, 0].set_title("Chirp FFT (Linear)")
    axes[1, 0].set_xlabel("Distance (m)")
    axes[1, 0].set_ylabel("Power, uncorrected")

    axes[1, 1].plot(rangeBins, chirpFFTScaledHalved)
    axes[1, 1].set_title("Chirp FFT (log-scaled)")
    axes[1, 1].set_xlabel("Distance (m)")
    axes[1, 1].set_ylabel("Amplitude (dB), uncorrected")

    figure.show()

    # Save linear results to a file
    saveData = np.column_stack((rangeBins, chirpFFTHalved))
    with open("./Data/{}/{}_rangeFFT_linear.csv".format(testName, testName), 'w') as f:
        np.savetxt(f, saveData, delimiter=',')
        logging.info("Saved linear range FFT results to file: ./Data/{}/{}_rangeFFT_linear.csv".format(testName, testName))

    # Save logscaled results to a file
    saveData = np.column_stack((rangeBins, chirpFFTScaledHalved))
    with open("./Data/{}/{}_rangeFFT_logscaled.csv".format(testName, testName), 'w') as f:
        np.savetxt(f, saveData, delimiter=',')
        logging.info("Saved log-scaled range FFT results to file: ./Data/{}/{}_rangeFFT_logscaled.csv".format(testName, testName))


def calculateDopper(testName, processedData, cfg):
    # Grab a frame worth of data on RX1 for analysis 
    frame = np.zeros((cfg.numChirpsPerFrame, cfg.numADCSamples))
    for chirp in range(0, cfg.numChirpsPerFrame):
        frame[chirp, :] = (processedData[0, chirp * cfg.numADCSamples:(chirp + 1) * cfg.numADCSamples])

    # Perform FFT on the frame data
    frameFFT = np.fft.fft(frame, axis=1)
    frameFFTHalved = frameFFT[:, :128]

    # Transform and zero-shift the results
    frameFFT2 = np.fft.fft(frameFFTHalved, axis=0)
    frameFFT2 = np.flip(np.fft.fftshift(frameFFT2, axes=0))

    # Range resolution
    rangeResolution = (5e-10 * C * cfg.sampleRate) / (cfg.freqSlope * cfg.numADCSamples)

    # Apply the range resolution factor to the range indices
    rangeValues = np.arange(cfg.numADCSamples // 2) * rangeResolution

    velocityResolution = C / (4e3 * cfg.startFrequency * cfg.rampEndTime * cfg.numChirps)

    # Apply the velocity resolution factor to the doppler indicies
    velocityBinning = np.arange(-cfg.numChirps // 2, cfg.numChirps // 2)
    velocityValues = velocityBinning * velocityResolution

    # amplitudeProfile = np.transpose(np.abs(frameFFT2))
    amplitudeProfile = np.transpose(20 * np.log10(np.abs(frameFFT2)))

    # Plot with units
    plt.figure(2)
    plt.imshow(amplitudeProfile, extent=[max(-5, velocityValues.min()), min(5, velocityValues.max()), rangeValues.min(), min(25, rangeValues.max())])
    plt.xlabel('Velocity (m/s)')
    plt.ylabel('Range (m)')
    plt.show()

    # Save the results to a file
    saveData = amplitudeProfile
    with open("./Data/{}/{}_dopplerProfile.csv".format(testName, testName), 'w') as f:
        np.savetxt(f, saveData, delimiter=',')
        logging.info("Saved doppler profile to file: ./Data/{}/{}_dopplerProfile.csv".format(testName, testName))




