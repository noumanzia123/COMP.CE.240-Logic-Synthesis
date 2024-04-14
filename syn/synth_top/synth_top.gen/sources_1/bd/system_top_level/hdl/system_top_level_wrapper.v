//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
//Date        : Thu Apr  4 15:57:38 2024
//Host        : WKS-94958-LT running 64-bit major release  (build 9200)
//Command     : generate_target system_top_level_wrapper.bd
//Design      : system_top_level_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module system_top_level_wrapper
   (pin_aud_bitclk,
    pin_aud_data,
    pin_aud_lr_clk,
    pin_aud_mclk,
    pin_clk125mhz,
    pin_i2c_sclk,
    pin_i2c_sdata,
    pin_keys,
    pin_leds_i2c,
    pin_rst_n);
  output pin_aud_bitclk;
  output pin_aud_data;
  output pin_aud_lr_clk;
  output pin_aud_mclk;
  input pin_clk125mhz;
  output pin_i2c_sclk;
  inout pin_i2c_sdata;
  input [3:0]pin_keys;
  output [3:0]pin_leds_i2c;
  input pin_rst_n;

  wire pin_aud_bitclk;
  wire pin_aud_data;
  wire pin_aud_lr_clk;
  wire pin_aud_mclk;
  wire pin_clk125mhz;
  wire pin_i2c_sclk;
  wire pin_i2c_sdata;
  wire [3:0]pin_keys;
  wire [3:0]pin_leds_i2c;
  wire pin_rst_n;

  system_top_level system_top_level_i
       (.pin_aud_bitclk(pin_aud_bitclk),
        .pin_aud_data(pin_aud_data),
        .pin_aud_lr_clk(pin_aud_lr_clk),
        .pin_aud_mclk(pin_aud_mclk),
        .pin_clk125mhz(pin_clk125mhz),
        .pin_i2c_sclk(pin_i2c_sclk),
        .pin_i2c_sdata(pin_i2c_sdata),
        .pin_keys(pin_keys),
        .pin_leds_i2c(pin_leds_i2c),
        .pin_rst_n(pin_rst_n));
endmodule
