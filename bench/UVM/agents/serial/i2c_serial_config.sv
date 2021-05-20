/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_serial_config.sv                                        @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Config file for serial agent                              @
@|  Data        :  - .04.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_SRL_CONFIG__
`define I2C_SRL_CONFIG__

class i2c_srl_config extends uvm_object;
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    `uvm_object_utils_begin (i2c_srl_config)
        `uvm_field_enum (uvm_active_passive_enum, is_active, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "i2c_srl_config");
        super.new(name);
    endfunction : new
endclass : i2c_srl_config

`endif // I2C_SRL_CONFIG__