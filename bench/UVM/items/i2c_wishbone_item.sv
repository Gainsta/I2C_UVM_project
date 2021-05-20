/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_wishbone_item.sv                                        @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Items for working with the WISHBONE interface             @
@|  Data        :  - .12.2020                                                @
@|  Notes                                                                     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_WISHBONE_ITEM__
`define I2C_WISHBONE_ITEM__

import uvm_pkg::*;

///////////////////////////////////////////////////////////////////////////////
// Item for WISHBONE interface                                               //
///////////////////////////////////////////////////////////////////////////////

class i2c_wishbone_item#(parameter LOW_ADDR_BITS = `LOW_ADDR_BITS, DATABUS_WIDTH = `DATABUS_WIDTH) extends uvm_sequence_item;

    //  Group: Variables
    rand logic [LOW_ADDR_BITS-1:0] addr;
    rand logic [DATABUS_WIDTH-1:0] data_i;
    rand bit we;

    logic [DATABUS_WIDTH-1:0]   data_o;

    //  Field macros
    `uvm_object_utils_begin(i2c_wishbone_item)
        `uvm_field_int(addr, UVM_DEFAULT)
        `uvm_field_int(data_i, UVM_DEFAULT)
        `uvm_field_int(data_o, UVM_DEFAULT)
        `uvm_field_int(we, UVM_DEFAULT)
    `uvm_object_utils_end

    //  Constructor: new
    function new(string name = "i2c_wishbone_item");
        super.new(name);
    endfunction: new

endclass: i2c_wishbone_item

`endif // I2C_WISHBONE_ITEM__