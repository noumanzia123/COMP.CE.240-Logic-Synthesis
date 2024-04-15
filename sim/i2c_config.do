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
add wave max_sclk
add wave min_sda
--add wave max_sda
add wave sdat_r
add wave sclk_r
add wave counter_sclk
add wave counter_bit
add wave counter_sda
--add wave counter_ack


force -deposit /rst_n 0 0, 1 {10 ns}
force -deposit /clk 0 0, 1 10 -r 20
--force -deposit /counter1_r 0 0
--force -deposit /counter2_r 0 0
--force -deposit /shift_left1_r 0 0
--force -deposit /shift_left2_r 0 0
--force -deposit /left_data_in EAAB 0
--force -deposit /right_data_in EAAB 0


