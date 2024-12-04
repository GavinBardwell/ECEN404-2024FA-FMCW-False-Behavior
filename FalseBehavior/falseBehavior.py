import numpy as np
from calculations import skew

def threshold_calculation(dataset, threshold_factor=0.09, eval_chirps=640):

    # Inputs: 
    #   dataset (ndarray): The dataset of FFT outputs with shape (frame, chirp, sample).
    #   threshold_factor (float): Additional factor to adjust the calculated threshold.

    if not isinstance(dataset, np.ndarray) or dataset.ndim != 3:
        raise ValueError("dataset must be a 3-dimensional numpy array: (frame, chirp, sample).")
    
    peak_to_average_ratios = np.zeros(eval_chirps)

    for i in range(eval_chirps):
        chirps = dataset[0, i, :]
        peak_to_average_ratios[i] = np.max(chirps) / np.mean(chirps)
    
    # Compute threshold
    threshold = np.nanmean(peak_to_average_ratios) + threshold_factor
    return threshold

def detect_false_behavior(chirp_FFT, skew_threshold=0.25, peak_average_threshold=0.1):

    # Input:
    #    chirp_FFT (ndarray): FFT output for a single chirp.
    
    if not isinstance(chirp_FFT, np.ndarray) or len(chirp_FFT) == 0:
        raise ValueError("chirp_FFT must be a non-empty numpy array.")
    
    # Compute key statistics
    peak = np.max(chirp_FFT)
    mean = np.mean(chirp_FFT)
    std_dev = np.std(chirp_FFT)
    skewness = skew(chirp_FFT)
    rms = np.sqrt(np.mean(chirp_FFT ** 2))

    # Derived metrics
    peak_to_average = peak / mean

    # Compute spectral entropy of chirp_FFT like MATLAB implementation
    # chirp_FFT_normalized = chirp_FFT / np.sum(chirp_FFT)
    # spectral_entropy = -np.sum(chirp_FFT_normalized * np.log2(chirp_FFT_normalized))

    # Detection logic
    is_false_behavior = (
        peak_to_average > peak_average_threshold or
        skewness < skew_threshold or 
        peak_to_average < (peak_average_threshold - 1/2 - 0.01)
    )

    dev_metrics = {
        "peak": peak,
        "mean": mean,
        "rms": rms,
        "std_dev": std_dev,
        "skewness": skewness,
        "peak_to_average": peak_to_average,
    }

    return is_false_behavior, dev_metrics


