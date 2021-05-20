/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_wishbone_monitor.sv                                     @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Monitor for WISHBONE agent                                @
@|  Data        :  - .04.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_WISHBONE_MONITOR__
`define I2C_WISHBONE_MONITOR__

class i2c_wishbone_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_wishbone_monitor)

    logic [7:0] TXR_data;
    logic [3:0] command;
    logic [7:0] data;

    i2c_transfer_item item;

    // Indicate when Reset is asserted
    event reset_asserted;
    event a_reset_asserted;

    //---------------------------------------
    // Virtual interface
    //---------------------------------------
    i2c_wishbone_vif vif;

    //---------------------------------------
    // Analysis ports
    //---------------------------------------
    uvm_analysis_port #(i2c_transfer_item) wb_item_rd_port;
    uvm_analysis_port #(i2c_transfer_item) wb_item_dnd_port;

    function new (string name, uvm_component parent);
        super.new(name, parent);
        item = new();
        wb_item_rd_port = new("wb_item_rd_port", this);
        wb_item_dnd_port = new("wb_item_dnd_port", this);
    endfunction : new

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
            get_and_send();
        join_none
    endtask : run_phase

    // Task: get_and_send
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Get item from vif and send
    task get_and_send();
        forever begin
            fork
                @reset_asserted;
                @a_reset_asserted;
                begin
                    @(posedge vif.clk iff (!vif.rst));
                    forever begin
                        fork
                            get_TXR();
                            get_CR();
                            get_AL();
                        join_any
                    end
                end
            join_any
            disable fork;
        end
    endtask : get_and_send

    // Task: reset
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when reset will appeared (1 - active)
    task reset();
        forever begin
            wait(vif.rst);
            -> reset_asserted;
            clear_all();
            `uvm_info("RST", {"Reset Asserted: ", get_type_name()}, UVM_HIGH)

            wait(!vif.rst);
            `uvm_info("RST", {"Reset Deasserted: ", get_type_name()}, UVM_HIGH)
        end
    endtask : reset

    // Task: a_reset
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when asynchronous reset will appeared (0 - active)
    task a_reset();
        forever begin
            wait(!vif.arst);
            -> a_reset_asserted;
            clear_all();
            `uvm_info("RST", {"Asynchronous Reset Asserted: ", get_type_name()}, UVM_HIGH)

            wait(vif.arst);
            `uvm_info("RST", {"Asynchronous Reset Deasserted: ", get_type_name()}, UVM_HIGH)
        end
    endtask : a_reset

    // Task: clear_all
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Clear all variables
    task clear_all();
        item.addr <= 'b0;
        item.data <= 'b0;
        item.RW <= 'b0;
    endtask : clear_all

    // Task: get_TXR
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // While we write in third register, we save transmitted data
    task get_TXR();
        forever begin
            @(vif.adr_i or vif.dat_i)
            if (vif.adr_i == 'h3) begin
                TXR_data = vif.dat_i;
            end
        end
    endtask : get_TXR

    // Task: get_CR
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // While we write in fourth register, we check the operation and decide what should we do with transmitted data
    task get_CR();
        forever begin
            @(vif.adr_i or vif.dat_i)
            if (vif.adr_i == 'h4 & vif.dat_i != 8'b0) begin
                command[3:0] = vif.dat_i[7:4];
                if (command[3]) begin
                    item.addr = TXR_data[7:1];
                    item.RW = TXR_data[0];
                end else if (command[1]) begin
                    // it's read station
                    forever begin
                        @(vif.adr_i)
                        if (vif.adr_i == 'h3) begin
                            #`DRIVER_READ;
                            data = vif.dat_o[7:0];
                            send_item();
                            break;
                        end
                    end
                end
            end
        end
    endtask : get_CR

    // Task: get_AL
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Test: try to get AL condition
    task get_AL();
        forever begin
            @(vif.dat_o)
            if (vif.adr_i == 3'h4 & vif.dat_i == 8'h0 & vif.dat_o[5] & !item.RW) begin
                wb_item_dnd_port.write(item);
                forever begin
                    @(vif.adr_i)
                    if (vif.adr_i == 'h4 & vif.dat_i != 8'b0 & vif.dat_i[7]) begin
                        break;
                    end
                end
            end
        end
    endtask : get_AL

    // Task: send_item
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Send data to analysis port after data is receive
    task send_item();
        item.data = data;
        `uvm_info("wb_monitor_item", $sformatf("Check item in monitor: addr = %h, data = %h, RW = %h", item.addr, item.data, item.RW), UVM_HIGH)
        wb_item_rd_port.write(item);
    endtask : send_item

endclass : i2c_wishbone_monitor
`endif // I2C_WISHBONE_MONITOR__