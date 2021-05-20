/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_config.sv                                               @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Config file for i2c testbench                             @
@|  Data        :  - .04.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_CONFIG__
`define I2C_CONFIG__

class i2c_config extends uvm_object;
    `uvm_object_utils(i2c_config)

    //Settings for Prescale register
    bit [15:0] i2c_prer = `I2C_PRER;

    int scl_drive_clk_period = ( 5 * (`I2C_PRER+1) * `SYS_CLK_PERIOD);
    int scl_drive_clk_half_period = ( 5 * (`I2C_PRER+1) * `CLK_HALF_PERIOD);
    int scl_drive_clk_quarter_period = (`SCL_DRIVE_CLK_HALF_PERIOD >> 1);

    //Different conditions
    bit arbitration_lost = 1'b0;
    //Simulate busy slave (for send NACK after addres send)
    bit slave_busy_addr = 1'b0;
    //for send NACK after data send
    bit slave_busy_data = 1'b0;
    //plus one reset during the test
    bit plus_rst = 1'b0;
    //use areset in the start of the test
    bit plus_arst = 1'b0;

    //Config for agents
    i2c_wb_config       i2c_wb_cfg;
    i2c_srl_config      i2c_srl_cfg;

    function new(string name = "i2c_config");
        super.new(name);
    endfunction : new

endclass : i2c_config

`endif // I2C_CONFIG__
