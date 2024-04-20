view source
view objects
view variables
view wave

delete wave *
--add wave *
add wave clk
add wave rst_n
add wave curr_state_r
add wave transmission_r
add wave max_sclk_c
add wave min_sda_c
--add wave max_sda
add wave sdat_r
add wave sclk_r
add wave counter_sclk_r
add wave counter_bit_r
add wave sdat_inout
add wave ack_flag_r
add wave nack_r
add wave counter_param_r
add wave param_status_r
add wave finished_r
--add wave counter_sda
--add wave counter_ack


force -deposit /rst_n 0 0, 1 {10 ns}
force -deposit /clk 0 0, 1 10 -r 20
--force -deposit /counter1_r 0 0
--force -deposit /counter2_r 0 0
--force -deposit /shift_left1_r 0 0
--force -deposit /shift_left2_r 0 0
--force -deposit /left_data_in EAAB 0
--force -deposit /right_data_in EAAB 0


