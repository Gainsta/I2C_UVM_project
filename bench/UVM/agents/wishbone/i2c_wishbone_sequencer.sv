/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_wishbone_sequencer.sv                                   @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Sequencer for WISHBONE agent                              @
@|  Data        :  - .12.2020                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_WISHBONE_SEQUENCER__
`define I2C_WISHBONE_SEQUENCER__

//typedef uvm_sequencer#(i2c_wishbone_item) i2c_wishbone_sequencer;

class i2c_wishbone_sequencer extends uvm_sequencer #(i2c_wishbone_item);
    `uvm_component_utils(i2c_wishbone_sequencer)

    //-----------------------------------------------
    // Ports & Exports
    //-----------------------------------------------
    uvm_analysis_port #(i2c_transfer_item) wb_item_wr_port;

    function new(string name = "i2c_wishbone_sequencer", uvm_component parent = null);
        super.new(name, parent);
        wb_item_wr_port  = new("wb_item_wr_port", this);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

endclass : i2c_wishbone_sequencer

`endif //I2C_WISHBONE_SEQUENCER__