/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_wishbone_driver.sv                                      @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Driver for working with WISHBONE interface                @
@|  Data        :  - .12.2020                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_WISHBONE_DRIVER__
`define I2C_WISHBONE_DRIVER__

///////////////////////////////////////////////////////////////////////////////
// Driver for WISHBONE interface                                             //
///////////////////////////////////////////////////////////////////////////////

class i2c_wishbone_driver extends uvm_driver#(i2c_wishbone_item);
    `uvm_component_utils(i2c_wishbone_driver)

    //---------------------------------------
    // Wishbone item
    i2c_wishbone_item item;

    //---------------------------------------
    // Virtual interface
    i2c_wishbone_vif vif;

    // Indicate when Reset is asserted
    event reset_asserted;
    event a_reset_asserted;

    function new(string name = "i2c_wishbone_driver", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //-----------------------------------------------------------
    // UVM phases : build_phase
    //-----------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    //-----------------------------------------------------------
    // UVM phases : connect_phase
    //-----------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (!uvm_config_db#(i2c_wishbone_vif)::get(.cntxt( this ),
                                                .inst_name( "" ),
                                                .field_name( "vif" ),
                                                .value( vif ))) begin
        `uvm_fatal("NOVIF", {"Virtaul interface must be set for:",
                    get_full_name(), ".vif"})
        end
    endfunction : connect_phase

    //-----------------------------------------------------------
    // UVM phases : run_phase
    //-----------------------------------------------------------
    task run_phase(uvm_phase phase);
        fork
            reset();
            a_reset();
            get_and_drive();
        join_none
    endtask : run_phase

    // Task: get_and_drive
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Get item from sequencer and drive vif
    task get_and_drive();
        forever begin
            fork
                @reset_asserted;
                @a_reset_asserted;
                begin
                    @(posedge vif.clk iff (!vif.rst));
                    forever begin
                        while (1) begin
                            seq_item_port.try_next_item(item);
                            if (item != null) break;
                            @(posedge vif.clk iff (!vif.rst));
                        end
                        set_control_bits();
                        drive_vif();
                        wait(vif.ack_o);
                        @(posedge vif.clk iff (!vif.rst));
                        #1;
                        take_vif();
                        seq_item_port.item_done();
                    end
                end
            join_any
            disable fork;
            if (item != null) seq_item_port.item_done();
        end
    endtask : get_and_drive

    // Task: reset
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when reset will appeared (1 - active)
    task reset();
        forever begin
            wait(vif.rst);
            -> reset_asserted;
            clear_vif();
            init_properties();
            `uvm_info("RST", {"Reset Asserted: ", get_type_name()}, UVM_MEDIUM)
            wait(!vif.rst);
            `uvm_info("RST", {"Reset Deasserted: ", get_type_name()}, UVM_MEDIUM)
        end
    endtask : reset

    // Task: a_reset
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when asynchronous reset will appeared (0 - active)
    task a_reset();
        forever begin
            wait(!vif.arst);
            -> a_reset_asserted;
            clear_vif();
            init_properties();
            `uvm_info("RST", {"Asynchronous Reset Asserted: ", get_type_name()}, UVM_MEDIUM)
            wait(vif.arst);
            `uvm_info("RST", {"Asynchronous Reset Deasserted: ", get_type_name()}, UVM_MEDIUM)
        end
    endtask : a_reset

    // Task: clear_vif
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Clear vif's signals
    task clear_vif();
        vif.adr_i <= 3'b0;
        vif.dat_i <= 8'b0;
        vif.we_i  <= 1'b0;
        vif.stb_i <= 1'b0;
        vif.cyc_i <= 1'b0;
    endtask : clear_vif

    // Function: init_properties
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Initialize class properties
    function void init_properties();
    endfunction : init_properties

    task set_control_bits();
        vif.stb_i <= 1'b1;
        vif.cyc_i <= 1'b1;
    endtask : set_control_bits

    // Task: drive_vif
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Drive vif activity
    task drive_vif();
        send_item(item);
    endtask : drive_vif

    // Task: take_vif
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Take vif answer
    task take_vif();
        take_item(item);
    endtask : take_vif

    // Task: send_item
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Send item to vif
    task send_item(i2c_wishbone_item item);
            vif.adr_i <= item.addr;
            vif.dat_i <= item.data_i;
            vif.we_i  <= item.we;
            vif.stb_i <= 1'b1;
            vif.cyc_i <= 1'b1;
            //`uvm_info("Drive_VIF", $sformatf("Send item to vif: adr = %h, data_i = %h, we = %b",
            //                                item.addr, item.data_i, item.we), UVM_MEDIUM);
    endtask : send_item

    // Task: take_item
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Take data from vif to item and stop the transfer
    task take_item(i2c_wishbone_item item);
            item.data_o = vif.dat_o;
            vif.stb_i <= 1'b0;
            vif.cyc_i <= 1'b0;
            //`uvm_info("Drive_VIF", $sformatf("Take item from vif: i2c_item.data_o = %h, vif.dat_o=%h",
            //                                    item.data_o, vif.dat_o), UVM_MEDIUM);
    endtask : take_item
endclass : i2c_wishbone_driver

`endif // I2C_WISHBONE_DRIVER__