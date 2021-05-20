/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_serial_driver.sv                                        @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Driver for working with SERIAL interface                  @
@|  Data        :  - .04.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_SERIAL_DRIVER__
`define I2C_SERIAL_DRIVER__

///////////////////////////////////////////////////////////////////////////////
// Driver for SERIAL interface                                               //
///////////////////////////////////////////////////////////////////////////////

class i2c_serial_driver extends uvm_driver#(i2c_transfer_item);
    `uvm_component_utils(i2c_serial_driver)

    //variables for delays
    logic [15:0] i2c_prer;

    int scl_drive_clk_period;
    int scl_drive_clk_half_period;
    int scl_drive_clk_quarter_period;

    //configuration bits
    bit slave_busy_addr;
    bit slave_busy_data;
    bit arbitration_lost;

    rand bit [1:0] arbitration_bits;

    i2c_transfer_item item;
    i2c_serial_item inner_item;

    //---------------------------------------
    // Virtual interface
    i2c_serial_vif vif;

    // Indicate when STO was received
    event STO_find;

    // Indicate when Reset is asserted
    event reset_asserted;
    event a_reset_asserted;

    function new(string name = "i2c_serial_driver", uvm_component parent);
        super.new(name, parent);
        inner_item = new();
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
    endtask : get_and_drive

    // Task: reset
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when reset will appeared (1 - active)
    task reset();
        forever begin
            wait(vif.rst);
            -> reset_asserted;
            clear_vif();
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
            clear_vif();
            `uvm_info("RST", {"Asynchronous Reset Asserted: ", get_type_name()}, UVM_HIGH)
            wait(vif.arst);
            `uvm_info("RST", {"Asynchronous Deasserted: ", get_type_name()}, UVM_HIGH)
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
            `uvm_info("STO", {"Find stop command: ", get_type_name()}, UVM_MEDIUM)
            clear_vif();
        end
    endtask : STO_receive

    // Task: STA_receive
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Wait when STA condition was send
    task STA_receive();
        @(negedge vif.sda_en_o iff (vif.scl_en_o));
        `uvm_info("STA", {"Find start command: ", get_type_name()}, UVM_MEDIUM)
        clear_vif();
    endtask : STA_receive

    // Task: clear_vif
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Clear vif's signals
    task clear_vif();
        vif.scl_i = 1'b1;
        vif.sda_i = 1'b1;

    endtask : clear_vif

    // Task: set_data
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Randomize data for transfer
    task set_data();
        assert(inner_item.randomize())
            else
                $fatal("FAIL on randomization of inner_item in serial_driver");
        inner_item.data_i = 8'h00;
        inner_item.counter = 4'd0;
    endtask: set_data

    // Task: drive_scl
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Drive scl_i activity
    task drive_scl();
        forever begin
            @(negedge vif.scl_en_o);
            vif.scl_i <= 1'b0;
            #scl_drive_clk_half_period;
            vif.scl_i <= 1'b1;
        end
    endtask : drive_scl

    // Task: release_sda
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Release SDA after the ACK or NACK send
    task release_sda();
        @(negedge vif.scl_en_o);
        vif.sda_i = 1'b1;
    endtask : release_sda

    // Task: send_ACK
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Send acknowledge to master
    task send_ACK();
        inner_item.ACK = 0;
        @(negedge vif.scl_en_o);
        vif.scl_i = 1'b0;
        // don't know why, but this delay should be here
        #scl_drive_clk_quarter_period;
        vif.sda_i = 1'b0;
        #scl_drive_clk_quarter_period;
        vif.scl_i = 1'b1;
        @(posedge vif.scl_en_o);
    endtask: send_ACK

    // Task: send_NACK
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Send n_acknowledge to master
    task send_NACK();
        inner_item.ACK = 1;
        @(negedge vif.scl_en_o);
        vif.scl_i = 1'b0;
        // don't know why, but this delay should be here
        #scl_drive_clk_quarter_period;
        vif.sda_i = 1'b1;
        #scl_drive_clk_quarter_period;
        vif.scl_i = 1'b1;
        @(posedge vif.scl_en_o);
    endtask: send_NACK

    // Task: read_ACK
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Read acknowledge from master
    task read_ACK();
        @(negedge vif.scl_en_o);
        vif.scl_i = 1'b0;
        #scl_drive_clk_quarter_period;
        vif.sda_i = 1'b1;
        #scl_drive_clk_quarter_period;
        vif.scl_i = 1'b1;
        @(posedge vif.scl_en_o);
        inner_item.ACK = vif.SDA;
    endtask: read_ACK

    // Task: drive_sda_addr
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Read addres of slave and RW
    task drive_sda_addr();
        forever begin
            if(arbitration_lost) begin
                std::randomize(arbitration_bits);
                @(negedge vif.SCL)
                #scl_drive_clk_quarter_period;
                if (arbitration_bits == 2'b00) begin
                    vif.sda_i = 1'b0;
                end else begin
                    vif.sda_i = 1'b1;
                end
                @(posedge vif.SCL);
                if (vif.sda_en_o != vif.SDA) begin
                    break;
                end
                inner_item.counter = inner_item.counter + 1'd1;
                if (inner_item.counter == 4'd8) begin
                    // after 8 iteration cancel address transfer
                    inner_item.counter = 4'd0;
                    break;
                end
            end else begin
                @(posedge vif.scl_en_o);
                inner_item.counter = inner_item.counter + 1'd1;
                if (inner_item.counter != 4'd8) begin
                    // on the 1-7'th clocks take address bits
                    inner_item.addr[6:0] = {inner_item.addr[5:0],vif.sda_en_o};
                end
                if (inner_item.counter == 4'd8) begin
                    // on the 8'th clock take RW bit
                    inner_item.RW = vif.sda_en_o;
                end
                if (inner_item.counter == 4'd8) begin
                    // after 8 iteration cancel address transfer
                    inner_item.counter = 4'd0;
                    break;
                end
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
            inner_item.data_i[7:0] = {inner_item.data_i[6:0],vif.sda_en_o};
            inner_item.counter = inner_item.counter + 1'd1;
            if (inner_item.counter == 4'd8) begin
                // after 8 iteration cancel data transfer
                inner_item.counter = 4'd0;
                break;
            end
        end
    endtask : write_to_slave

    // Task: read_from_slave
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Read 1 byte of data from slave
    task read_from_slave();
        forever begin
            @(negedge vif.scl_en_o);
            #scl_drive_clk_quarter_period;
            // when SCL is low, set SDA
            vif.sda_i = inner_item.data_o[7];
            @(posedge vif.scl_en_o);
            // prepare (shift) data register for next transaction
            inner_item.data_o[7:0] = {inner_item.data_o[6:0],1'b0};
            inner_item.counter = inner_item.counter + 1'd1;
            if (inner_item.counter == 4'd8) begin
                // after 8 iteration cancel data transfer
                inner_item.counter = 4'd0;
                break;
            end
        end
    endtask : read_from_slave

    // Task: drive_sda
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Read/write data to slave
    task drive_sda();
        if (!inner_item.RW) begin
            fork
                release_sda();
                write_to_slave();
            join
        end else begin
            read_from_slave();
        end
    endtask : drive_sda

    // Task: drive_write
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Control the write from master to slave cycle
    task drive_write();
        forever begin
            set_data();
            fork
                drive_scl();
                drive_sda();
            join_any
            disable fork;
            if(slave_busy_data) begin
                send_NACK();
                release_sda();
                break;
            end else begin
                send_ACK();
                release_sda();
            end
        end
    endtask: drive_write

    // Task: drive_read
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Control the read from slave to master cycle
    task drive_read();
        forever begin
            set_data();
            fork
                drive_scl();
                drive_sda();
            join_any
            disable fork;
            read_ACK();
            if(inner_item.ACK) begin
                break;
            end
        end
    endtask: drive_read

    // Task: drive_slave
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Full control of slave during transfer
    task drive_slave();
        set_data();
        fork
            drive_scl();
            drive_sda_addr();
        join_any
        disable fork;
        if(slave_busy_addr | arbitration_lost) begin
            send_NACK();
        end else begin
            send_ACK();
            if (inner_item.RW) begin
                drive_read();
            end else begin
                drive_write();
            end
        end
    endtask: drive_slave

endclass : i2c_serial_driver

`endif // I2C_SERIAL_DRIVER__