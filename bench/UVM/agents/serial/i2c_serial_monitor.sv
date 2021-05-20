/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_serial_monitor.sv                                       @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Monitor for SERIAL agent                                  @
@|  Data        :  - .04.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_SERIAL_MONITOR__
`define I2C_SERIAL_MONITOR__

class i2c_serial_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_serial_monitor)

    logic [6:0] addr;
    logic [7:0] data;
    logic RW;

    i2c_transfer_item item;
    i2c_serial_item inner_item;

    //---------------------------------------
    // Virtual interface
    i2c_serial_vif vif;

    //---------------------------------------
    // Analysis ports
    //---------------------------------------

    uvm_analysis_port #(i2c_transfer_item) srl_item_wr_port;
    uvm_analysis_port #(i2c_transfer_item) srl_item_rd_port;
    uvm_analysis_port #(i2c_transfer_item) srl_item_dnd_port;

    // Indicate when STO was received
    event STO_find;

    // Indicate when Reset is asserted
    event reset_asserted;
    event a_reset_asserted;

    function new (string name, uvm_component parent);
        super.new(name, parent);
        inner_item = new();
        item = new();
        srl_item_wr_port = new("srl_item_wr_port", this);
        srl_item_rd_port = new("srl_item_rd_port", this);
        srl_item_dnd_port = new("srl_item_dnd_port", this);
    endfunction : new

    //-----------------------------------------------------------
    // UVM phases : connect_phase
    //-----------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (!uvm_config_db#(i2c_serial_vif)::get(.cntxt( this ),
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
            STO_receive();
            get_and_write();
        join_none
    endtask : run_phase

    // Task: get_and_write
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Get item from sequencer and drive vif
    task get_and_write();
        forever begin
            fork
                @reset_asserted;
                @a_reset_asserted;
                @STO_find;
                begin
                    @(posedge vif.clk iff (!vif.rst));
                    forever begin
                        // Start work after finding START command
                        STA_receive();
                        forever begin
                            fork
                                STA_receive();
                                drive_slave();
                            join_any
                            disable fork;
                        end
                    end
                end
            join_any
            disable fork;
        end
    endtask : get_and_write

    // Task: reset
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when reset will appeared (1 - active)
    task reset();
        forever begin
            wait(vif.rst);
            -> a_reset_asserted;
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
            `uvm_info("RST", {"Asynchronous Reset Asserted: ", get_type_name()}, UVM_HIGH)
            wait(vif.arst);
            `uvm_info("RST", {"Asynchronous Reset Deasserted: ", get_type_name()}, UVM_HIGH)
        end
    endtask : a_reset

    // Task: STO_receive
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when STO condition was send
    task STO_receive();
        forever begin
            @(negedge vif.sda_en_o iff (vif.scl_en_o));
            @(posedge vif.sda_en_o iff (vif.scl_en_o));
            -> STO_find;
            `uvm_info("STO", {"Find stop command: ", get_type_name()}, UVM_HIGH)
        end
    endtask : STO_receive

    // Task: STA_receive
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when STA condition was send
    task STA_receive();
        @(negedge vif.sda_en_o iff (vif.scl_en_o));
        `uvm_info("STA", {"Find start command: ", get_type_name()}, UVM_HIGH)
    endtask : STA_receive

    // Task: read_ACK
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Read acknowledge
    task read_ACK();
        @(negedge vif.scl_en_o);
        @(posedge vif.scl_en_o);
        inner_item.ACK = vif.SDA;
    endtask: read_ACK

    // Task: drive_sda_addr
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Read addres of slave and RW
    task drive_sda_addr();
        inner_item.counter = 4'd0;
        forever begin
            @(posedge vif.scl_en_o);
            inner_item.counter = inner_item.counter + 1'd1;
            if (inner_item.counter != 4'd8) begin
                // on the 1-7'th clocks take address bits
                addr[6:0] = {addr[5:0],vif.sda_en_o};
            end
            if (inner_item.counter == 4'd8) begin
                // on the 8'th clock take RW bit
                RW = vif.sda_en_o;
            end
            if (inner_item.counter == 4'd8) begin
                // after 8 iteration cancel address transfer
                item.addr = addr;
                item.RW = RW;
                inner_item.counter = 4'd0;
                break;
            end
        end
    endtask : drive_sda_addr

    // Task: write_to_slave
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Write 1 byte of data to slave
    task write_to_slave();
        forever begin
            @(posedge vif.scl_en_o);
            // when SCL is high, take data from SDA-line
            data[7:0] = {data[6:0],vif.sda_en_o};
            inner_item.counter = inner_item.counter + 1'd1;
            if (inner_item.counter == 4'd8) begin
                // after 8 iteration cancel data transfer
                inner_item.counter = 4'd0;
                item.data = data;
                `uvm_info("srl_monitor_item", $sformatf("Check item in monitor: addr = %h, data = %h, RW = %h", item.addr, item.data, item.RW), UVM_HIGH)
                srl_item_rd_port.write(item);
                break;
            end
        end
    endtask : write_to_slave

    // Task: read_from_slave
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Read 1 byte of data from slave
    task read_from_slave();
        forever begin
            @(posedge vif.scl_en_o);
            // when SCL is high, take data from SDA-line
            item.data[7:0] = {item.data[6:0],vif.sda_i};
            inner_item.counter = inner_item.counter + 1'd1;
            if (inner_item.counter == 4'd8) begin
                // after 8 iteration cancel data transfer
                inner_item.counter = 4'd0;
                `uvm_info("srl_monitor_item", $sformatf("Check item in monitor: addr = %h, data = %h, RW = %h", item.addr, item.data, item.RW), UVM_HIGH)
                srl_item_wr_port.write(item);
                break;
            end
        end
    endtask : read_from_slave

    // Task: drive_sda
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Read/write data to slave
    task drive_sda();
        if (!item.RW) begin
            write_to_slave();
        end else begin
            read_from_slave();
        end
    endtask : drive_sda

    // Task: drive_transfer
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Control the write\read cycle
    task drive_transfer();
        forever begin
            drive_sda();
            read_ACK();
            if(inner_item.ACK) begin
                break;
            end
        end
    endtask: drive_transfer

    // Task: drive_slave
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Observe slave during the transfer
    task drive_slave();
        drive_sda_addr();
        read_ACK();
        if(!inner_item.ACK) begin
            drive_transfer();
        end else if(!item.RW) begin
            srl_item_dnd_port.write(item);
        end
    endtask: drive_slave

endclass : i2c_serial_monitor

`endif // I2C_SERIAL_MONITOR__