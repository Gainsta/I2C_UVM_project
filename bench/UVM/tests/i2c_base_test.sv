/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_base_test.sv                                            @
@|  Project     : I2C_Test :: I2C                                            @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : All tests for I2C controller                              @
@|  Data        :  - .01.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_BASE_TEST__
`define I2C_BASE_TEST__

///////////////////////////////////////////////////////////////////////////////
// Base test                                                                 //
///////////////////////////////////////////////////////////////////////////////

// Class: i2c_base_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Base test
class i2c_base_test extends uvm_test;
    `uvm_component_utils(i2c_base_test)

    i2c_config          i2c_env_cfg;
    i2c_environment     i2c_env;
    i2c_wb_config       i2c_wb_cfg;
    i2c_srl_config      i2c_srl_cfg;
    i2c_reg_block       i2c_mem_block;
    i2c_base_sequence   i2c_base_seq;
    i2c_stop_sequence   i2c_stop_seq;

    bit test_pass;

    function new(string name = "i2c_base_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_env_cfg = i2c_config::type_id::create("i2c_env_cfg");
        i2c_wb_cfg = i2c_wb_config::type_id::create("i2c_wb_cfg");
        i2c_srl_cfg = i2c_srl_config::type_id::create("i2c_srl_cfg");
        i2c_mem_block = i2c_reg_block::type_id::create("i2c_mem_block");
        i2c_mem_block.build();
        i2c_env = i2c_environment::type_id::create( .name("i2c_env"), .parent(this));

        uvm_config_db#(i2c_config)::set(null, "*", "i2c_env_cfg", i2c_env_cfg);
        uvm_config_db#(i2c_reg_block)::set(this, "*", "reg_block", i2c_mem_block);

        i2c_env_cfg.i2c_wb_cfg = i2c_wb_cfg;
        i2c_env_cfg.i2c_srl_cfg = i2c_srl_cfg;

        uvm_top.enable_print_topology = 1; // If set, then the entire testbench topology is printed just after completion of the end_of_elaboration phase
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_base_seq = i2c_base_sequence::type_id::create("i2c_base_seq");
        i2c_stop_seq = i2c_stop_sequence::type_id::create("i2c_stop_seq");
        i2c_stop_seq.model = i2c_mem_block;
        phase.phase_done.set_drain_time(this, `DRAIN_TIME);
    endtask: main_phase;

    function void report_phase(uvm_phase phase);
        uvm_report_server svr = uvm_report_server::get_server();

        test_pass = (svr.get_severity_count(UVM_ERROR) == 0)
                    && (svr.get_severity_count(UVM_FATAL) == 0);

        if (test_pass) begin
            `uvm_info(get_type_name(), "\nTEST PASSED\n", UVM_NONE)
        end
        else begin
            `uvm_error(get_type_name(), "\nTEST FAILED\n")
        end
    endfunction : report_phase

    virtual function void pre_abort();
        // Call extract and report phases
        // so that the state of the scoreboard is printed
        // if the test ends with a UVM_FATAL
        report_phase(null);
    endfunction : pre_abort

endclass: i2c_base_test

///////////////////////////////////////////////////////////////////////////////
// Check test                                                                //
///////////////////////////////////////////////////////////////////////////////

// Class: i2c_check_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Check test
class i2c_check_test extends i2c_base_test;
    `uvm_component_utils(i2c_check_test)

    i2c_check_sequence i2c_check_seq;

    function new (string name = "i2c_check_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_check_seq = i2c_check_sequence::type_id::create("i2c_check_seq");
        // check this -v
        i2c_check_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_check_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_check_test

///////////////////////////////////////////////////////////////////////////////
// Built-in Register Tests                                                   //
///////////////////////////////////////////////////////////////////////////////

// Class: i2c_reg_hw_reset_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Register reset test sequence
class i2c_reg_hw_reset_test extends i2c_base_test;
    `uvm_component_utils(i2c_reg_hw_reset_test)

    uvm_reg_hw_reset_seq rst_seq;

    function new (string name = "i2c_reg_hw_reset_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        uvm_resource_db #(bit)::set({"REG::", i2c_mem_block.TXR.get_full_name()}, "NO_REG_HW_RESET_TEST", 1);
        uvm_resource_db #(bit)::set({"REG::", i2c_mem_block.CR.get_full_name()}, "NO_REG_HW_RESET_TEST", 1);
        rst_seq = uvm_reg_hw_reset_seq::type_id::create("rst_seq");
        rst_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        rst_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_reg_hw_reset_test

// Class: i2c_reg_bit_bash_seq
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Write 1's and 0's to all bits in register and then check-reads
class i2c_reg_bit_bash_seq extends i2c_base_test;
    `uvm_component_utils(i2c_reg_bit_bash_seq)

    uvm_reg_bit_bash_seq bit_bash_seq;

    function new (string name = "i2c_reg_bit_bash_seq", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        uvm_resource_db #(bit)::set({"REG::", i2c_mem_block.TXR.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1);
        uvm_resource_db #(bit)::set({"REG::", i2c_mem_block.RXR.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1);
        uvm_resource_db #(bit)::set({"REG::", i2c_mem_block.CR.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1);
        uvm_resource_db #(bit)::set({"REG::", i2c_mem_block.SR.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1);
        bit_bash_seq = uvm_reg_bit_bash_seq::type_id::create("bit_bash_seq");
        bit_bash_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        bit_bash_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_reg_bit_bash_seq

///////////////////////////////////////////////////////////////////////////////
// Packet transfer tests                                                     //
///////////////////////////////////////////////////////////////////////////////

// Class: i2c_single_write_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Send one block of data to slave
class i2c_single_write_test extends i2c_base_test;
    `uvm_component_utils(i2c_single_write_test)

    i2c_single_write_sequence i2c_single_write_seq;

    function new (string name = "i2c_single_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_env_cfg.plus_arst = 1'b1;
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_single_write_seq = i2c_single_write_sequence::type_id::create("i2c_single_write_seq");
        i2c_single_write_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_single_write_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_single_write_test

// Class: i2c_single_read_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Get one block of data from slave
class i2c_single_read_test extends i2c_base_test;
    `uvm_component_utils(i2c_single_read_test)

    i2c_single_read_sequence i2c_single_read_seq;

    function new (string name = "i2c_single_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_env_cfg.plus_arst = 1'b1;
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_single_read_seq = i2c_single_read_sequence::type_id::create("i2c_single_read_seq");
        i2c_single_read_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_single_read_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_single_read_test

// Class: i2c_multiple_write_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Send several block of data to the controller
class i2c_multiple_write_test extends i2c_base_test;
    `uvm_component_utils(i2c_multiple_write_test)

    i2c_multiple_write_sto_sequence i2c_multiple_write_seq;

    function new (string name = "i2c_multiple_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_multiple_write_seq = i2c_multiple_write_sto_sequence::type_id::create("i2c_multiple_write_seq");
        i2c_multiple_write_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_multiple_write_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_multiple_write_test

// Class: i2c_multidirectional_write_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Send several block of data to the controller
class i2c_multidirectional_write_test extends i2c_base_test;
    `uvm_component_utils(i2c_multidirectional_write_test)

    rand logic [2:0] n_address;

    i2c_multiple_write_sequence i2c_multiple_write_seq;
    i2c_multiple_write_sto_sequence i2c_multiple_write_s_seq;

    function new (string name = "i2c_multidirectional_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_multiple_write_seq = i2c_multiple_write_sequence::type_id::create("i2c_multiple_write_seq");
        i2c_multiple_write_seq.model = i2c_mem_block;
        i2c_multiple_write_s_seq = i2c_multiple_write_sto_sequence::type_id::create("i2c_multiple_write_s_seq");
        i2c_multiple_write_s_seq.model = i2c_mem_block;
        n_address = $urandom_range(4, 1);
        `uvm_info("i2c_multidirectional_write_test", $sformatf("n_address is %d", n_address + 2), UVM_MEDIUM)
        phase.raise_objection(this);
        for (int i = 0; i <= n_address; i++) begin
            i2c_multiple_write_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        end
        i2c_multiple_write_s_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_multidirectional_write_test

// Class: i2c_multiple_read_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Read several block of data from controller
class i2c_multiple_read_test extends i2c_base_test;
    `uvm_component_utils(i2c_multiple_read_test)

    i2c_multiple_read_sequence i2c_multiple_read_seq;

    function new (string name = "i2c_multiple_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_multiple_read_seq = i2c_multiple_read_sequence::type_id::create("i2c_multiple_read_seq");
        i2c_multiple_read_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_multiple_read_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_multiple_read_test

// Class: i2c_multidirectional_read_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Receives several block of data from different slaves
class i2c_multidirectional_read_test extends i2c_base_test;
    `uvm_component_utils(i2c_multidirectional_read_test)

    rand logic [2:0] n_address;

    i2c_multiple_read_sequence i2c_multiple_read_seq;

    function new (string name = "i2c_multidirectional_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_multiple_read_seq = i2c_multiple_read_sequence::type_id::create("i2c_multiple_read_seq");
        i2c_multiple_read_seq.model = i2c_mem_block;
        n_address = $urandom_range(4, 1);
        `uvm_info("i2c_multidirectional_read_test", $sformatf("n_address is %d", n_address + 1), UVM_MEDIUM)
        phase.raise_objection(this);
        for (int i = 0; i <= n_address; i++) begin
            i2c_multiple_read_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        end
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_multidirectional_read_test

// Class: i2c_multidirectional_rw_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Receives several block of data from different slaves
class i2c_multidirectional_rw_test extends i2c_base_test;
    `uvm_component_utils(i2c_multidirectional_rw_test)

    rand logic [2:0] n_address;
    rand logic RW;

    i2c_multiple_read_sequence i2c_multiple_read_seq;
    i2c_multiple_write_sequence i2c_multiple_write_seq;

    function new (string name = "i2c_multidirectional_rw_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_multiple_read_seq = i2c_multiple_read_sequence::type_id::create("i2c_multiple_read_seq");
        i2c_multiple_write_seq = i2c_multiple_write_sequence::type_id::create("i2c_multiple_write_seq");
        i2c_multiple_read_seq.model = i2c_mem_block;
        i2c_multiple_write_seq.model = i2c_mem_block;
        n_address = $urandom_range(4, 1);
        `uvm_info("i2c_multidirectional_rw_test", $sformatf("n_address is %d", n_address + 1), UVM_MEDIUM)
        phase.raise_objection(this);
        `uvm_info("i2c_multidirectional_rw_test", $sformatf("i2c_prer is %d", i2c_env_cfg.i2c_prer), UVM_MEDIUM)
        for (int i = 0; i <= n_address; i++) begin
            RW = $urandom();
            if (RW) begin
                `uvm_info("i2c_multidirectional_rw_test", {"Start read sequence ", get_type_name()}, UVM_MEDIUM)
                i2c_multiple_read_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
            end else begin
                `uvm_info("i2c_multidirectional_rw_test", {"Start write sequence ", get_type_name()}, UVM_MEDIUM)
                i2c_multiple_write_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
            end
        end
        i2c_stop_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_multidirectional_rw_test

// Class: i2c_PREP_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// i2c_multidirectional_rw_test with random PREP
class i2c_PREP_test extends i2c_base_test;
    `uvm_component_utils(i2c_PREP_test)

    rand logic [15:0] i2c_prer;
    rand logic [2:0] n_address;
    rand logic RW;

    i2c_multiple_read_sequence i2c_multiple_read_seq;
    i2c_multiple_write_sequence i2c_multiple_write_seq;

    function new (string name = "i2c_PREP_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // randomize I2C_PRER and send it to the cfg
        i2c_env_cfg.i2c_prer = $urandom_range(50, 1);
        i2c_env_cfg.scl_drive_clk_period = (5 * (i2c_env_cfg.i2c_prer+1) * `SYS_CLK_PERIOD);
        i2c_env_cfg.scl_drive_clk_half_period = (5 * (i2c_env_cfg.i2c_prer+1) * `CLK_HALF_PERIOD);
        i2c_env_cfg.scl_drive_clk_quarter_period = (i2c_env_cfg.scl_drive_clk_half_period >> 1);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        `uvm_info("i2c_PREP_test", $sformatf("i2c_prer is %d", i2c_env_cfg.i2c_prer), UVM_MEDIUM)
        i2c_multiple_read_seq = i2c_multiple_read_sequence::type_id::create("i2c_multiple_read_seq");
        i2c_multiple_write_seq = i2c_multiple_write_sequence::type_id::create("i2c_multiple_write_seq");
        i2c_multiple_read_seq.i2c_prer = i2c_env_cfg.i2c_prer;
        i2c_multiple_write_seq.i2c_prer = i2c_env_cfg.i2c_prer;
        i2c_multiple_read_seq.model = i2c_mem_block;
        i2c_multiple_write_seq.model = i2c_mem_block;
        n_address = $urandom_range(4, 1);
        `uvm_info("i2c_PREP_test", $sformatf("n_address is %d", n_address + 1), UVM_MEDIUM)
        phase.raise_objection(this);
        for (int i = 0; i <= n_address; i++) begin
            RW = $urandom();
            if (RW) begin
                `uvm_info("i2c_PREP_test", {"Start read sequence ", get_type_name()}, UVM_MEDIUM)
                i2c_multiple_read_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
            end else begin
                `uvm_info("i2c_PREP_test", {"Start write sequence ", get_type_name()}, UVM_MEDIUM)
                i2c_multiple_write_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
            end
        end
        if(!RW) begin
            i2c_stop_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        end
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_PREP_test

// Class: i2c_slave_busy_adr_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Simulate situation when slave busy and send NACK back after address
class i2c_slave_busy_adr_test extends i2c_base_test;
    `uvm_component_utils(i2c_slave_busy_adr_test)

    i2c_write_to_busy_slave_sequence i2c_wr_busy_slave_seq;

    function new (string name = "i2c_slave_busy_adr_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_env_cfg.slave_busy_addr = 1'b1;
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_wr_busy_slave_seq = i2c_write_to_busy_slave_sequence::type_id::create("i2c_wr_busy_slave_seq");
        i2c_wr_busy_slave_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_wr_busy_slave_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_slave_busy_adr_test

// Class: i2c_slave_busy_dat_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Simulate situation when slave busy and sends NACK back after data
class i2c_slave_busy_dat_test extends i2c_base_test;
    `uvm_component_utils(i2c_slave_busy_dat_test)

    i2c_write_to_busy_slave_sequence i2c_wr_busy_slave_seq;

    function new (string name = "i2c_slave_busy_dat_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_env_cfg.slave_busy_data = 1'b1;
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_wr_busy_slave_seq = i2c_write_to_busy_slave_sequence::type_id::create("i2c_wr_busy_slave_seq");
        i2c_wr_busy_slave_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_wr_busy_slave_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_slave_busy_dat_test

// Class: i2c_arbitration_lost_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Triggers the arbitration lost condition
class i2c_arbitration_lost_test extends i2c_base_test;
    `uvm_component_utils(i2c_arbitration_lost_test)

    i2c_arbitration_lost_sequence i2c_arb_lost_seq;

    function new (string name = "i2c_arbitration_lost_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_env_cfg.arbitration_lost = 1'b1;
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_arb_lost_seq = i2c_arbitration_lost_sequence::type_id::create("i2c_arb_lost_seq");
        i2c_arb_lost_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_arb_lost_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        i2c_arb_lost_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_arbitration_lost_test

// Class: i2c_multidirectional_rw_IEN_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Receives several block of data from different slaves
class i2c_multidirectional_rw_IEN_test extends i2c_base_test;
    `uvm_component_utils(i2c_multidirectional_rw_IEN_test)

    rand logic [2:0] n_address;
    rand logic RW;

    i2c_multiple_read_IEN_sequence i2c_multiple_read_seq;
    i2c_multiple_write_IEN_sequence i2c_multiple_write_seq;

    function new (string name = "i2c_multidirectional_rw_IEN_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_multiple_read_seq = i2c_multiple_read_IEN_sequence::type_id::create("i2c_multiple_read_seq");
        i2c_multiple_write_seq = i2c_multiple_write_IEN_sequence::type_id::create("i2c_multiple_write_seq");
        i2c_multiple_read_seq.model = i2c_mem_block;
        i2c_multiple_write_seq.model = i2c_mem_block;
        n_address = $urandom_range(4, 1);
        `uvm_info("i2c_multidirectional_rw_IEN_test", $sformatf("n_address is %d", n_address + 1), UVM_MEDIUM)
        phase.raise_objection(this);
        `uvm_info("i2c_multidirectional_rw_IEN_test", $sformatf("i2c_prer is %d", i2c_env_cfg.i2c_prer), UVM_MEDIUM)
        for (int i = 0; i <= n_address; i++) begin
            RW = $urandom();
            if (RW) begin
                `uvm_info("i2c_multidirectional_rw_IEN_test", {"Start read sequence ", get_type_name()}, UVM_MEDIUM)
                i2c_multiple_read_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
            end else begin
                `uvm_info("i2c_multidirectional_rw_IEN_test", {"Start write sequence ", get_type_name()}, UVM_MEDIUM)
                i2c_multiple_write_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
            end
        end
        i2c_stop_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_multidirectional_rw_IEN_test

// Class: i2c_single_read_with_rst_test
// _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
// Get one block of data from slave. During the test we send rst.
class i2c_single_read_with_rst_test extends i2c_base_test;
    `uvm_component_utils(i2c_single_read_with_rst_test)

    i2c_single_read_with_rst_sequence i2c_single_read_seq;

    function new (string name = "i2c_single_read_with_rst_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        i2c_env_cfg.plus_rst = 1'b1;
    endfunction: build_phase

    task main_phase(uvm_phase phase);
        super.main_phase(phase);
        i2c_single_read_seq = i2c_single_read_with_rst_sequence::type_id::create("i2c_single_read_seq");
        i2c_single_read_seq.model = i2c_mem_block;
        phase.raise_objection(this);
        i2c_single_read_seq.start(.sequencer(i2c_env.i2c_wb_agent.i2c_wb_sqncr));
        phase.drop_objection(this);
    endtask: main_phase

endclass: i2c_single_read_with_rst_test

`endif // I2C_BASE_TEST__