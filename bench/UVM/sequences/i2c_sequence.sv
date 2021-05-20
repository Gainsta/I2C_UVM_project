/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_sequence.sv                                             @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : All sequences for debug I2C controller                    @
@|  Data        :  - .02.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_SEQUENCE__
`define I2C_SEQUENCE__

///////////////////////////////////////////////////////////////////////////////
// Base sequence                                                             //
///////////////////////////////////////////////////////////////////////////////

// Class: i2c_base_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Test sequence to debugging driver
class i2c_base_sequence extends uvm_reg_sequence;
    `uvm_object_utils( i2c_base_sequence )

    logic [15:0] i2c_prer = `I2C_PRER;

    i2c_transfer_item item;
    i2c_reg_block   i2c_mem_block;
    uvm_status_e    status;
    uvm_reg_data_t  value;

    function new(string name = "i2c_base_sequence");
        super.new(name);
        item = new();
    endfunction: new

    virtual task body();
        $cast( i2c_mem_block, model );
        i2c_mem_block.reset();
        //i2c_mem_block.print();
    endtask: body

endclass: i2c_base_sequence

///////////////////////////////////////////////////////////////////////////////
// Configure sequence                                                        //
///////////////////////////////////////////////////////////////////////////////

// Class: i2c_cfg_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Class which contain cfg for stert transfer and useful functions
class i2c_cfg_sequence extends i2c_base_sequence;
    `uvm_object_utils( i2c_cfg_sequence )
    `uvm_declare_p_sequencer(i2c_wishbone_sequencer)

    logic RxACK, busy, AL, TIP, IF;
    logic [2:0] reserved;
    rand bit ACK;

    function new(string name = "i2c_cfg_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        i2c_mem_block.PRERlo.write(status, i2c_prer[7:0]);
        i2c_mem_block.PRERhi.write(status, i2c_prer[15:8]);
        i2c_mem_block.CTR.EN.set(1'b1);
        i2c_mem_block.CTR.update(status);
    endtask: body

    virtual task set_item(bit RW);
        assert(item.randomize())
        else
            $fatal("FAIL on randomization of item in sequence");
        item.RW = RW;
        if(!item.RW) begin
            p_sequencer.wb_item_wr_port.write(item);
        end
    endtask: set_item;

    virtual task set_item_data();
        item.data = $urandom();
        if(!item.RW) begin
            p_sequencer.wb_item_wr_port.write(item);
        end
    endtask: set_item_data;

    virtual task send_STO();
        i2c_mem_block.CR.reset();
        i2c_mem_block.CR.STO.set(1'b1);
        i2c_mem_block.CR.IACK.set(1'b1);
        i2c_mem_block.CR.update(status);
        // We need to wait because STO command need some time to be complete
        #`SCL_DRIVE_CLK_PERIOD;
        #`SCL_DRIVE_CLK_PERIOD;
    endtask: send_STO

    virtual task send_addr_RW();
        i2c_mem_block.TXR.nextByte.set(item.addr);
        i2c_mem_block.TXR.LSB.set(item.RW);
        i2c_mem_block.TXR.update(status);
        i2c_mem_block.CR.reset();
        i2c_mem_block.CR.STA.set(1'b1);
        i2c_mem_block.CR.WR.set(1'b1);
        i2c_mem_block.CR.IACK.set(1'b1);
        i2c_mem_block.CR.update(status);
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP, IF});
            if (TIP) begin
                break;
            end
        end
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP, IF});
            if (TIP == 0 | IF) begin
                break;
            end
        end
    endtask: send_addr_RW

    virtual task send_data_nSTO();
        i2c_mem_block.TXR.write(status, item.data);
        i2c_mem_block.CR.reset();
        i2c_mem_block.CR.WR.set(1'b1);
        i2c_mem_block.CR.IACK.set(1'b1);
        i2c_mem_block.CR.update(status);
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP,IF});
            if (TIP) begin
                break;
            end
        end
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP,IF});
            if (TIP == 0 | IF) begin
                break;
            end
        end
    endtask: send_data_nSTO

    virtual task send_data_STO();
        i2c_mem_block.TXR.write(status, item.data);
        i2c_mem_block.CR.reset();
        i2c_mem_block.CR.STO.set(1'b1);
        i2c_mem_block.CR.WR.set(1'b1);
        i2c_mem_block.CR.IACK.set(1'b1);
        i2c_mem_block.CR.update(status);
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP,IF});
            if (TIP) begin
                break;
            end
        end
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP,IF});
            if (TIP == 0 | IF) begin
                break;
            end
        end
    endtask: send_data_STO

    virtual task receive_data_STO();
        i2c_mem_block.CR.reset();
        i2c_mem_block.CR.STO.set(1'b1);
        i2c_mem_block.CR.RD.set(1'b1);
        i2c_mem_block.CR.ACK.set(1'b1);
        i2c_mem_block.CR.IACK.set(1'b1);
        i2c_mem_block.CR.update(status);
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP, IF});
            if (TIP) begin
                break;
            end
        end
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP, IF});
            if (TIP == 0 | IF) begin
                break;
            end
        end
        i2c_mem_block.RXR.read(status, item.data);
    endtask: receive_data_STO

    virtual task receive_data_nSTO();
        i2c_mem_block.CR.reset();
        i2c_mem_block.CR.RD.set(1'b1);
        i2c_mem_block.CR.ACK.set(1'b0);
        i2c_mem_block.CR.IACK.set(1'b1);
        i2c_mem_block.CR.update(status);
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP, IF});
            if (TIP) begin
                break;
            end
        end
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP, IF});
            if (TIP == 0 | IF) begin
                break;
            end
        end
        i2c_mem_block.RXR.read(status, item.data);
    endtask: receive_data_nSTO

endclass: i2c_cfg_sequence

///////////////////////////////////////////////////////////////////////////////
// Check sequence                                                            //
///////////////////////////////////////////////////////////////////////////////

// Class: i2c_check_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Test sequence to debugging driver
class i2c_check_sequence extends i2c_base_sequence;
    `uvm_object_utils( i2c_check_sequence )

    logic [7:0] test;

    function new(string name = "i2c_check_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        #`SYS_CLK_PERIOD;
        #`SYS_CLK_PERIOD;
        #`SYS_CLK_PERIOD;
        `uvm_info("Sequence","Write to PRERhi", UVM_MEDIUM);
        i2c_mem_block.PRERhi.write(status, { 8'hf0 } );
        `uvm_info("Sequence","Write to PRERlo", UVM_MEDIUM);
        i2c_mem_block.PRERlo.write(status, { 8'h0a } );
        `uvm_info("Sequence","Read from PRERhi", UVM_MEDIUM);
        i2c_mem_block.PRERhi.read(status, value );
        `uvm_info("Sequence","Read from PRERlo", UVM_MEDIUM);
        i2c_mem_block.PRERlo.read(status, value );
        `uvm_info("Sequence","Write to PRERlo", UVM_MEDIUM);
        i2c_mem_block.PRERlo.write(status, { 8'haa } );
        `uvm_info("Sequence","Read from PRERlo", UVM_MEDIUM);
        i2c_mem_block.PRERlo.read(status, value );
        `uvm_info("Sequence","Set EN and IEN in CTR register", UVM_MEDIUM);
        i2c_mem_block.CTR.EN.set( 1'b1);
        i2c_mem_block.CTR.IEN.set( 1'b1 );
        test = i2c_mem_block.CTR.get();
        `uvm_info("i2c_check_sequence", $sformatf("CTR after get is %h", test), UVM_MEDIUM)
        i2c_mem_block.CTR.update(status);
        if (status == UVM_IS_OK) begin
            `uvm_info("i2c_check_sequence","Status of the CTR update is UVM_IS_OK", UVM_MEDIUM)
        end
        if (status == UVM_NOT_OK) begin
            `uvm_info("i2c_check_sequence","Status of the CTR update is UVM_NOT_OK", UVM_MEDIUM)
        end
        i2c_mem_block.CTR.read(status, test );
        `uvm_info("i2c_check_sequence", $sformatf("CTR after read is %h", test), UVM_MEDIUM)
        i2c_mem_block.CTR.EN.mirror(status);
        test = i2c_mem_block.CTR.get_mirrored_value();
        `uvm_info("i2c_check_sequence", $sformatf("CTR after mirror is %h", test), UVM_MEDIUM)
        if (status == UVM_IS_OK) begin
            `uvm_info("i2c_check_sequence","Status of the CTR.EN mirror is UVM_IS_OK", UVM_MEDIUM)
        end
        i2c_mem_block.print();
    endtask: body

endclass: i2c_check_sequence

///////////////////////////////////////////////////////////////////////////////
// Packet transfer sequences                                                 //
///////////////////////////////////////////////////////////////////////////////

// Class: i2c_stop_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Send one stop signal
class i2c_stop_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_stop_sequence )

    function new(string name = "i2c_stop_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        send_STO();
    endtask: body

endclass: i2c_stop_sequence

// Class: i2c_single_write_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Send one package of data to slave
class i2c_single_write_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_single_write_sequence )

    function new(string name = "i2c_single_write_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        //We need wait a bit, because we 2 time reset our device
        #`SYS_CLK_PERIOD;
        #`SYS_CLK_PERIOD;
        #`SYS_CLK_PERIOD;
        super.body();
        set_item(1'b0);
        // start send addres
        send_addr_RW();
        if (!RxACK) begin
            //send data to slave
            send_data_STO();
            if (RxACK) begin
                `uvm_info("i2c_single_write_sequence", $sformatf("RxACK after the write cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
            end
        end else begin
            `uvm_info("i2c_single_write_sequence", $sformatf("RxACK after the address send cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
        end
    endtask: body

endclass: i2c_single_write_sequence

// Class: i2c_single_read_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Get one package of data from slave.
class i2c_single_read_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_single_read_sequence )

    function new(string name = "i2c_single_read_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        //We need wait a bit, because we 2 time reset our device
        #`SYS_CLK_PERIOD;
        #`SYS_CLK_PERIOD;
        #`SYS_CLK_PERIOD;
        super.body();
        set_item(1'b1);
        send_addr_RW();
        if (!RxACK) begin
            //receive data from slave
            receive_data_STO();
            //check RxACK to valid the correct data transfer
            if (!RxACK) begin
                `uvm_info("i2c_single_read_sequence", $sformatf("RxACK after the read cycle is %h (should be 1)", RxACK), UVM_MEDIUM)
            end
        end else begin
            `uvm_info("i2c_single_read_sequence", $sformatf("RxACK after the address send cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
        end
    endtask: body

endclass: i2c_single_read_sequence

// Class: i2c_multiple_write_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Write several package of data to one slave without STO in the end
class i2c_multiple_write_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_multiple_write_sequence )

    rand logic [3:0] n_blocks;
    bit STO;

    function new(string name = "i2c_multiple_write_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        n_blocks = $urandom_range(6, 0);
        `uvm_info("i2c_multiple_write_sequence", $sformatf("n_blocks is %d", (4'h9 - n_blocks)), UVM_HIGH)
        STO = 1'b0;
        set_item(1'b0);
        // start send addres
        send_addr_RW();
        if (!RxACK) begin
            // start send data
            send_data_nSTO();
            forever begin
                if (!RxACK & !STO) begin
                    set_item_data();
                    send_data_nSTO();
                    if(n_blocks == 3'd7) begin
                        STO = 1'b1;
                    end else begin
                        n_blocks = n_blocks + 1'b1;
                    end
                end else begin
                    break;
                end
            end
        end else begin
            `uvm_info("i2c_multiple_write_sequence", $sformatf("RxACK after the address send cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
        end
    endtask: body

endclass: i2c_multiple_write_sequence

// Class: i2c_multiple_write_sto_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Write several package of data to one slave with STO in the end
class i2c_multiple_write_sto_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_multiple_write_sto_sequence )

    rand logic [3:0] n_blocks;
    bit STO;

    function new(string name = "i2c_multiple_write_sto_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        n_blocks = $urandom_range(6, 0);
        `uvm_info("i2c_multiple_write_sto_sequence", $sformatf("n_blocks is %d", (4'hA - n_blocks)), UVM_HIGH)
        STO = 1'b0;
        set_item(1'b0);
        // start send addres
        send_addr_RW();
        if (!RxACK) begin
            // start send data
            send_data_nSTO();
            forever begin
                if (!RxACK & !STO) begin
                    set_item_data();
                    send_data_nSTO();
                    if(n_blocks == 3'd7) begin
                        STO = 1'b1;
                    end else begin
                        n_blocks = n_blocks + 1'b1;
                    end
                end else begin
                    set_item_data();
                    send_data_STO();
                    break;
                end
            end
        end else begin
            `uvm_info("i2c_multiple_write_sto_sequence", $sformatf("RxACK after the address send cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
        end
    endtask: body

endclass: i2c_multiple_write_sto_sequence

// Class: i2c_multiple_read_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Read several package of data from one slave
class i2c_multiple_read_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_multiple_read_sequence )

    rand logic [3:0] n_blocks;
    bit STO;

    function new(string name = "i2c_multiple_read_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        n_blocks = $urandom_range(6, 0);
        `uvm_info("i2c_multiple_read_sequence", $sformatf("n_blocks is %d", (4'h9 - n_blocks)), UVM_HIGH)
        STO = 1'b0;
        set_item(1'b1);
        // start send addres
        send_addr_RW();
        if (!RxACK) begin
            forever begin
                // start receive data
                if (!STO) begin
                    receive_data_nSTO();
                    if(n_blocks == 3'd7) begin
                        receive_data_STO();
                        STO = 1'b1;
                    end else begin
                        n_blocks = n_blocks + 1'b1;
                    end
                end else begin
                    break;
                end
            end
        end else begin
            `uvm_info("i2c_multiple_read_sequence", $sformatf("RxACK after the address send cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
        end
    endtask: body

endclass: i2c_multiple_read_sequence

// Class: i2c_write_to_busy_slave_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Write to slave which now is busy
class i2c_write_to_busy_slave_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_write_to_busy_slave_sequence )

    function new(string name = "i2c_write_to_busy_slave_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        set_item(1'b0);
        // start send addres
        send_addr_RW();
        if (!RxACK) begin
            // start send data
            send_data_nSTO();
            if (!RxACK ) begin
                set_item_data();
                send_data_nSTO();
            end else begin
                `uvm_info("i2c_write_to_busy_slave_sequence", $sformatf("RxACK after the data send cycle is %h (slave is busy)", RxACK), UVM_MEDIUM)
                send_STO();
            end
        end else begin
            `uvm_info("i2c_write_to_busy_slave_sequence", $sformatf("RxACK after the address send cycle is %h (slave not exist or busy)", RxACK), UVM_MEDIUM)
            send_STO();
        end
    endtask: body

endclass: i2c_write_to_busy_slave_sequence

// Class: i2c_arbitration_lost_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Triggers the arbitration lost condition
class i2c_arbitration_lost_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_arbitration_lost_sequence )

    function new(string name = "i2c_arbitration_lost_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        set_item(1'b1);
        // start send addres
        send_addr_RW();
        if (!RxACK & !AL) begin
            //send data to slave
            send_data_nSTO();
            if (RxACK) begin
                `uvm_info("i2c_arbitration_lost_sequence", $sformatf("RxACK after the write cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
            end
        end else begin
            if(AL) begin
                `uvm_info("i2c_arbitration_lost_sequence", $sformatf("AL during the address send cycle is %h", AL), UVM_MEDIUM)
            end else begin
                `uvm_info("i2c_arbitration_lost_sequence", $sformatf("RxACK after the address send cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
            end
        end
        send_STO();
    endtask: body

endclass: i2c_arbitration_lost_sequence

// Class: i2c_multiple_write_IEN_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Write several package of data to one slave without STO in the end and IEN
class i2c_multiple_write_IEN_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_multiple_write_IEN_sequence )

    rand logic [3:0] n_blocks;
    bit STO;

    function new(string name = "i2c_multiple_write_IEN_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        i2c_mem_block.CTR.IEN.set(1'b1);
        i2c_mem_block.CTR.update(status);
        n_blocks = $urandom_range(6, 0);
        `uvm_info("i2c_multiple_write_IEN_sequence", $sformatf("n_blocks is %d", (4'h9 - n_blocks)), UVM_HIGH)
        STO = 1'b0;
        set_item(1'b0);
        // start send addres
        send_addr_RW();
        if (!RxACK) begin
            // start send data
            send_data_nSTO();
            forever begin
                if (!RxACK & !STO) begin
                    set_item_data();
                    send_data_nSTO();
                    if(n_blocks == 3'd7) begin
                        STO = 1'b1;
                    end else begin
                        n_blocks = n_blocks + 1'b1;
                    end
                end else begin
                    break;
                end
            end
        end else begin
            `uvm_info("i2c_multiple_write_IEN_sequence", $sformatf("RxACK after the address send cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
        end
    endtask: body

endclass: i2c_multiple_write_IEN_sequence

// Class: i2c_multiple_read_IEN_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Read several package of data from one slave with IEN
class i2c_multiple_read_IEN_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_multiple_read_IEN_sequence )

    rand logic [3:0] n_blocks;
    bit STO;

    function new(string name = "i2c_multiple_read_IEN_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        i2c_mem_block.CTR.IEN.set(1'b1);
        i2c_mem_block.CTR.update(status);
        n_blocks = $urandom_range(6, 0);
        `uvm_info("i2c_multiple_read_IEN_sequence", $sformatf("n_blocks is %d", (4'h9 - n_blocks)), UVM_HIGH)
        STO = 1'b0;
        set_item(1'b1);
        // start send addres
        send_addr_RW();
        if (!RxACK) begin
            forever begin
                // start receive data
                if (!STO) begin
                    receive_data_nSTO();
                    if(n_blocks == 3'd7) begin
                        receive_data_STO();
                        STO = 1'b1;
                    end else begin
                        n_blocks = n_blocks + 1'b1;
                    end
                end else begin
                    break;
                end
            end
        end else begin
            `uvm_info("i2c_multiple_read_IEN_sequence", $sformatf("RxACK after the address send cycle is %h (should be 0)", RxACK), UVM_MEDIUM)
        end
    endtask: body

endclass: i2c_multiple_read_IEN_sequence

// Class: i2c_single_read_with_rst_sequence
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Set STA bit and start to read. (This need to improve our coverage)
class i2c_single_read_with_rst_sequence extends i2c_cfg_sequence;
    `uvm_object_utils( i2c_single_read_with_rst_sequence )

    function new(string name = "i2c_single_read_with_rst_sequence");
        super.new(name);
    endfunction: new

    virtual task body();
        super.body();
        set_item(1'b1);
        i2c_mem_block.TXR.nextByte.set(item.addr);
        i2c_mem_block.TXR.LSB.set(item.RW);
        i2c_mem_block.TXR.update(status);
        i2c_mem_block.CR.reset();
        i2c_mem_block.CR.STA.set(1'b1);
        i2c_mem_block.CR.RD.set(1'b1);
        i2c_mem_block.CR.IACK.set(1'b1);
        i2c_mem_block.CR.update(status);
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP, IF});
            if (TIP) begin
                break;
            end
        end
        forever begin
            i2c_mem_block.SR.read(status, {RxACK, busy, AL, reserved, TIP, IF});
            if (TIP == 0 | IF) begin
                break;
            end
        end
    endtask: body

endclass: i2c_single_read_with_rst_sequence

`endif // I2C_SEQUENCE__