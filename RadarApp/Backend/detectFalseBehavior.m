function isFalse = detectFalseBehavior(simData)
    %{
    sim data will be the data post fft. It will be in the form
    simData.resp -- Resp is a MxP matrix. This is the response of the input signal from FFT
    
    simData.rng_grid -- rng_grid is the range samples at which range-doppler response is
        evaulated, grid column of length M
    
    simData.dop_grid -- dop_grid is the frequency samples that range dop is evaluates 
    %}
    %USER CODE GOES HERE
    power_vs_range = sum(abs(simData.resp), 2); % Sum over the Doppler dimension
    peak = max(power_vs_range);
    mean_val = mean(power_vs_range);  % 'mean' is a MATLAB function, so using 'mean_val' to avoid conflict
    peak_to_average = peak / mean_val;
    
    % Calculate if within range
    peak_average_threshold = .556;
    p_a = peak_to_average > peak_average_threshold;
    p_a_l = peak_to_average < (peak_average_threshold - 0.49);
    
    % Using threshold return true or false
    if p_a || p_a_l
        result = true;
    else
        result = false;
    end
    isFalse = result;
    %%USER CODE GOES HERE
end
