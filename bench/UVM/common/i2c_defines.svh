/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_defines.svh                                             @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Defines for I2C_test                                      @
@|  Data        :  - .03.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_DEFINES__
`define I2C_DEFINES__

///////////////////////////////////////////////////////////////////////////////
// TESTBENCH DEFINES                                                         //
///////////////////////////////////////////////////////////////////////////////

`define LOW_ADDR_BITS       3
`define ADDR_BITS           7
`define DATABUS_WIDTH       8

// defines for interfaces
`define DATABUS_WIDTH 8
`define LOW_ADDR_WIDTH 3
`define IS_ASSERT_CHECKS_WB  0
`define IS_ASSERT_CHECKS_SRL 0

//`timescale 1ns/1ps
`define CLK_HALF_PERIOD     5
`define SYS_CLK_PERIOD      10

`define DRIVER_READ         (`SYS_CLK_PERIOD+1)

`define I2C_PRER        16'h0016
`define I2C_PRERhi      ((`I2C_PRER&16'hff00) >> 8)
`define I2C_PRERlo      (`I2C_PRER&16'h00ff)

`define SCL_DRIVE_CLK_PERIOD            ( 5 * (`I2C_PRER+1) * `SYS_CLK_PERIOD)
`define SCL_DRIVE_CLK_HALF_PERIOD       ( 5 * (`I2C_PRER+1) * `CLK_HALF_PERIOD)
`define SCL_DRIVE_CLK_QUARTER_PERIOD    (`SCL_DRIVE_CLK_HALF_PERIOD >> 1)

// Simulation
`define DRAIN_TIME    (`SCL_DRIVE_CLK_PERIOD * 12)

`endif // I2C_DEFINES__
