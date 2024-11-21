function isFalse = detectFalseBehavior(simData)
    %{
    % sim data will be the data post fft. It will be in the form
    % simData.resp_frames -- Resp is a 1x1 struct. Each struct contains a 1x64 cell, and each cell is a 2048x256 complex double (the frame)
    %
    % simData.rng_grid -- rng_grid is the range samples at which range-doppler response is
    %     evaluated, grid column of length M
    %
    % simData.dop_grid -- dop_grid is the frequency samples that range dop is evaluated 
    %
    % The dataset for threshold calculation will be the 6th frame from simData.resp
    %}
    %USER CODE GOES HERE

    % Extract the 6th frame from simData.resp for threshold calculation
    dataset = simData.resp_frames{1}(6); % Get the 6th cell from the 1x64 cell array
    dataset = squeeze(dataset); % Remove singleton dimensions if necessary

    % Calculate threshold using the threshold_calculation function
    threshold = threshold_calculation(dataset);

    % Calculate power vs range
    power_vs_range = sum(abs(simData.resp{1}{6}), 2); % Sum over the Doppler dimension for the 6th frame
    peak = max(power_vs_range);
    mean_val = mean(power_vs_range);  % 'mean' is a MATLAB function, so using 'mean_val' to avoid conflict
    peak_to_average = peak / mean_val;
    
    % Calculate if within range
    peak_average_threshold = threshold;
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

function threshold = threshold_calculation(dataset)
    % Dimension of dataset is (2048, 256), calculate average peak-to-average ratio for the 6th frame
    peak_to_average_array = zeros(size(dataset, 1), 1);
    for i = 1:size(dataset, 1)
        peak_to_average_array(i) = max(dataset(i, :)) / mean(dataset(i, :));
    end
    
    threshold = nanmean(peak_to_average_array) + 0.09;
end
