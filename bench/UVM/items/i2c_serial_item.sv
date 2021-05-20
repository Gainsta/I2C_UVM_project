/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_serial_item.sv                                          @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Items for working with the SERIAL interface               @
@|  Data        :  - .02.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_SERIAL_ITEM__
`define I2C_SERIAL_ITEM__

import uvm_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// Item for SERIAL interface                                                 //
///////////////////////////////////////////////////////////////////////////////

// Task: i2c_transfer_item
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Item with data to transfer through the DUT
class i2c_transfer_item#(parameter ADDR_BITS = `ADDR_BITS, DATABUS_WIDTH = `DATABUS_WIDTH) extends uvm_sequence_item;

    //  Group: Variables
    rand logic [ADDR_BITS-1:0] addr;
    rand logic [DATABUS_WIDTH-1:0] data;
    bit RW;

    //  Field macros
    `uvm_object_utils_begin(i2c_transfer_item)
        `uvm_field_int(addr, UVM_DEFAULT)
        `uvm_field_int(data, UVM_DEFAULT)
        `uvm_field_int(RW, UVM_DEFAULT)
    `uvm_object_utils_end

    //  Constructor: new
    function new(string name = "i2c_transfer_item");
        super.new(name);
    endfunction: new

endclass: i2c_transfer_item

// Task: i2c_serial_item
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Item with data to use in serial_driver
class i2c_serial_item extends uvm_sequence_item;

    //  Group: Variables
    rand logic [7:0] data_o;
    rand logic continue_ACK; // delet it if randomization of ACK not needed
    logic [3:0] counter = 4'b0000;
    logic [6:0] addr;
    logic [7:0] data_i;
    logic RW;
    bit STO;
    bit STA;
    bit ACK;

    //  Field macros
    `uvm_object_utils_begin(i2c_serial_item)
        `uvm_field_int(data_o, UVM_DEFAULT)
        `uvm_field_int(continue_ACK, UVM_DEFAULT)
        `uvm_field_int(counter, UVM_DEFAULT)
        `uvm_field_int(addr, UVM_DEFAULT)
        `uvm_field_int(data_i, UVM_DEFAULT)
        `uvm_field_int(RW, UVM_DEFAULT)
        `uvm_field_int(STO, UVM_DEFAULT)
        `uvm_field_int(STA, UVM_DEFAULT)
        `uvm_field_int(ACK, UVM_DEFAULT)
    `uvm_object_utils_end

    //  Constructor: new
    function new(string name = "i2c_serial_item");
        super.new(name);
    endfunction: new

endclass: i2c_serial_item

`endif // I2C_SERIAL_ITEM__