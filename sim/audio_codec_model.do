view source
view objects
view variables
view wave

delete wave *
add wave *

force -deposit /rst_n 0 0, 1 {10 ns}
force -deposit /aud_lrclk_in 0 0, 1 10416 -r 20833
force -deposit /aud_bclk_in 0 0, 1 250 -r 500
force -deposit /aud_data_in 0 0, 1 500 -r 1000


