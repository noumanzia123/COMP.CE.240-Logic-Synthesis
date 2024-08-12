sample_rate = 48e3;
data_width = 16;
period = 1/sample_rate;
pulse_length = period/2;
bclk_period_max = pulse_length/data_width;
bclk_freq_min = 1/bclk_period_max

bclk_period_min = 75e-9;
bclk_freq_max = 1/bclk_period_min


%%% in form of rate %%%
sample_rate = 48e3;
period = 1/sample_rate;
pulse_length = 1/sample_rate*2;
bclk_period_max = 1/((sample_rate*2)*data_width);
bclk_freq_min = sample_rate*2*(data_width+1);


bclk_period_min = 75e-9;
bclk_freq_max = 1/bclk_period_min;