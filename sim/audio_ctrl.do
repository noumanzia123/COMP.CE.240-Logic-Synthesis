view source
view objects
view variables
view wave

delete wave *
add wave *
--sim:/audio_ctrl/max1_c
--sim:/audio_ctrl/max2_c
--sim:/audio_ctrl/sample_rate_g
--sim:/audio_ctrl/ref_clk_freq_g
--sim:/audio_ctrl/data_width_g


force -deposit /rst_n 0 0, 1 {10 ns}
force -deposit /clk 0 0, 1 25 -r 50
force -deposit /counter1_r 0 0
force -deposit /counter2_r 0 0
--force -deposit /shift_left1_r 0 0
--force -deposit /shift_left2_r 0 0
force -deposit /left_data_in EAAB 0
force -deposit /right_data_in EAAB 0


