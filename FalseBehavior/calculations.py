import pyfftw
import numpy as np

def fft(RX_separated, num_RX=4, NUM_SAMPLES=256):

    hanning = np.hanning(NUM_SAMPLES)

    # Input and output real FFTs
    fft_input = pyfftw.empty_aligned(NUM_SAMPLES, dtype='float32')
    fft_output = pyfftw.empty_aligned(NUM_SAMPLES // 2 + 1, dtype='complex64')

    # FFT object for real-to-complex FFT, 256 -> 129 
    fft_object = pyfftw.FFTW(fft_input, fft_output, flags=('FFTW_PATIENT',), direction='FFTW_FORWARD')

    # Perform FFT on each frame (each 256 samples) for each RX antenna over all 128 chirps
    # Store results in a 3D array (RX, chirp, FFT output)
    RX_fft = np.zeros((num_RX, RX_separated.shape[1] // NUM_SAMPLES, NUM_SAMPLES // 2 + 1), dtype='complex64')

    # Loop over each RX antenna and chirp to perform FFT
    for RX in range(num_RX):
        for chirp in range(RX_separated.shape[1] // NUM_SAMPLES):
            fft_input[:] = hanning * RX_separated[RX, chirp * NUM_SAMPLES:(chirp + 1) * NUM_SAMPLES]
            RX_fft[RX, chirp, :] = fft_object()

    return RX_fft

# Now do it all with numpy's fft module
# RX_fft_np = np.zeros((num_RX, RX_separated.shape[1] // NUM_SAMPLES, NUM_SAMPLES // 2 + 1), dtype='complex64')

# for RX in range(num_RX):
    # for chirp in range(RX_separated.shape[1] // NUM_SAMPLES):
        # RX_fft_np[RX, chirp, :] = np.fft.rfft(RX_separated[RX, chirp * NUM_SAMPLES:(chirp + 1) * NUM_SAMPLES])


# Define a skew function, the scipy implementation of skew is strange to me

def skew(dataset):
    x0 = dataset - np.mean(dataset)
    s2 = np.mean(x0 ** 2) # biased variance est
    m3 = np.mean(x0 ** 3) # third moment
    skew = m3 / s2 ** (3 / 2)
    return skew