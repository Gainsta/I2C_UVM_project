/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_scoreboard.sv                                           @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Scoreboard to check the tests                             @
@|  Data        :  - .04.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_SCOREBOARD__
`define I2C_SCOREBOARD__

`uvm_analysis_imp_decl(_wishbone_write)
`uvm_analysis_imp_decl(_serial_read)

`uvm_analysis_imp_decl(_wishbone_read)
`uvm_analysis_imp_decl(_serial_write)

`uvm_analysis_imp_decl(_serial_denied)
`uvm_analysis_imp_decl(_wishbone_denied)

class i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_scoreboard)

    int m_matches, m_mismatches;
    protected i2c_transfer_item m_wb_wr[$];
    protected i2c_transfer_item m_wb_rd[$];
    protected i2c_transfer_item m_srl_wr[$];
    protected i2c_transfer_item m_srl_rd[$];

    protected int c_wb_wr;
    protected int c_wb_rd;
    protected int c_srl_wr;
    protected int c_srl_rd;

    //-----------------------------------------------
    // Ports & Exports
    //-----------------------------------------------
    uvm_analysis_imp_wishbone_write#(i2c_transfer_item, i2c_scoreboard)     wishbone_write;
    uvm_analysis_imp_serial_read#(i2c_transfer_item, i2c_scoreboard)    serial_read;

    uvm_analysis_imp_wishbone_read#(i2c_transfer_item, i2c_scoreboard)       wishbone_read;
    uvm_analysis_imp_serial_write#(i2c_transfer_item, i2c_scoreboard)       serial_write;

    uvm_analysis_imp_serial_denied#(i2c_transfer_item, i2c_scoreboard)    serial_denied;
    uvm_analysis_imp_wishbone_denied#(i2c_transfer_item, i2c_scoreboard)    wishbone_denied;

    function new(string name = "i2c_scoreboard", uvm_component parent);
        super.new(name, parent);
        m_matches = 0;
        m_mismatches = 0;
        c_wb_wr = 0;
        c_wb_rd = 0;
        c_srl_wr = 0;
        c_srl_rd = 0;
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        wishbone_write  = new("wishbone_write", this);
        serial_read = new("serial_read", this);

        wishbone_read = new("wishbone_read", this);
        serial_write = new("serial_write", this);

        serial_denied = new("serial_denied", this);
        wishbone_denied = new("wishbone_denied", this);
   endfunction : build_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask : run_phase

    function void report_phase( uvm_phase phase);
        `uvm_info("Inorder Comparator", $sformatf("Matches: %0d", m_matches), UVM_MEDIUM)
        `uvm_info("Inorder Comparator", $sformatf("Mismatches: %0d", m_mismatches), UVM_MEDIUM)
        cmp_transfers();
    endfunction : report_phase

    // Function: cmp_transfers
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Compare the number of send and receive packeg
    protected virtual function void cmp_transfers();
        int n_loses_wr = 0;
        int n_loses_rd = 0;
        if(c_wb_wr != c_srl_rd) begin
            if(c_wb_wr > c_srl_rd) begin
                n_loses_wr = c_wb_wr - c_srl_rd;
            end else begin
                n_loses_wr = c_srl_rd - c_wb_wr;
            end
        end
        if(c_wb_rd != c_srl_wr) begin
            if(c_wb_rd > c_srl_wr) begin
                n_loses_rd = c_wb_rd - c_srl_wr;
            end else begin
                n_loses_rd = c_srl_wr - c_wb_rd;
            end
        end
        if (n_loses_wr != 0) begin
            `uvm_error("Comparator Mismatch", $sformatf("Number of packages, lost during the write transfer: %0d", n_loses_wr))
        end
        if (n_loses_rd != 0) begin
            `uvm_error("Comparator Mismatch", $sformatf("Number of packages, lost during the read transfer: %0d", n_loses_rd))
        end
        if (n_loses_wr == 0 & n_loses_rd == 0) begin
            `uvm_info("Inorder Comparator", $sformatf("No package lost"), UVM_MEDIUM)
        end
    endfunction : cmp_transfers

    // Function: m_proc_data_w
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    //
    protected virtual function void m_proc_data_w();

        i2c_transfer_item wb_wr = m_wb_wr.pop_front();
        i2c_transfer_item srl_rd = m_srl_rd.pop_front();

        if(!wb_wr.compare(srl_rd)) begin
            `uvm_error("Comparator Mismatch", $sformatf("Send data (addr = %h,RW = %h, data = %h) does not match receive data (addr = %h, RW = %h, data = %h)", wb_wr.addr, wb_wr.RW, wb_wr.data, srl_rd.addr, srl_rd.RW, srl_rd.data))
            m_mismatches++;
        end else begin
            m_matches++;
        end
    endfunction : m_proc_data_w

    // Function: m_proc_data_r
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    //
    protected virtual function void m_proc_data_r();

        i2c_transfer_item wb_rd = m_wb_rd.pop_front();
        i2c_transfer_item srl_wr = m_srl_wr.pop_front();

        if(!srl_wr.compare(wb_rd)) begin
            `uvm_error("Comparator Mismatch", $sformatf("addr = %h data = %h does not match addr = %h data = %h", wb_rd.addr, wb_rd.data, srl_wr.addr, srl_wr.data))
            m_mismatches++;
        end else begin
            m_matches++;
        end
    endfunction : m_proc_data_r

    // Function: write_wishbone_write
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    //
    virtual function void write_wishbone_write(i2c_transfer_item wb);
        c_wb_wr = c_wb_wr + 1'b1;
        m_wb_wr.push_back(wb);
        `uvm_info("write_wishbone_write", $sformatf("Check item in scoreboard: addr = %h, data = %h", wb.addr, wb.data), UVM_MEDIUM)
        if(m_srl_rd.size()) begin
            m_proc_data_w();
        end
    endfunction : write_wishbone_write

    // Function: write_serial_read
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    //
    virtual function void write_serial_read(i2c_transfer_item srl);
        c_srl_rd = c_srl_rd + 1'b1;
        m_srl_rd.push_back(srl);
        `uvm_info("write_serial_read", $sformatf("Check item in scoreboard: addr = %h, data = %h", srl.addr, srl.data), UVM_MEDIUM)
        if(m_wb_wr.size()) begin
            m_proc_data_w();
        end
    endfunction : write_serial_read

    // Function: write_wishbone_read
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    //
    virtual function void write_wishbone_read(i2c_transfer_item wb);
        c_wb_rd = c_wb_rd + 1'b1;
        m_wb_rd.push_back(wb);
        `uvm_info("write_wishbone_read", $sformatf("Check item in scoreboard: addr = %h, data = %h", wb.addr, wb.data), UVM_MEDIUM)
        if(m_srl_wr.size()) begin
            m_proc_data_r();
        end
    endfunction : write_wishbone_read

    // Function: write_serial_write
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    //
    virtual function void write_serial_write(i2c_transfer_item srl);
        c_srl_wr = c_srl_wr + 1'b1;
        m_srl_wr.push_back(srl);
        `uvm_info("write_serial_write", $sformatf("Check item in scoreboard: addr = %h, data = %h", srl.addr, srl.data), UVM_MEDIUM)
        if(m_wb_rd.size()) begin
            m_proc_data_r();
        end
    endfunction : write_serial_write

    // Function: write_serial_denied
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Used when slave denied the transfer
    virtual function void write_serial_denied(i2c_transfer_item srl);
        c_wb_wr = c_wb_wr - 1'b1;
        m_wb_wr.pop_back();
        `uvm_info("write_serial_denied", $sformatf("One packege delited from c_wb_wr"), UVM_MEDIUM)
    endfunction : write_serial_denied

    // Function: write_wishbone_denied
    // _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    // Used when find arbitration lost
    virtual function void write_wishbone_denied(i2c_transfer_item wb);
        c_wb_wr = c_wb_wr - 1'b1;
        m_wb_wr.pop_back();
        `uvm_info("write_wishbone_denied", $sformatf("One packege delited from c_wb_wr"), UVM_MEDIUM)
    endfunction : write_wishbone_denied

endclass : i2c_scoreboard

`endif // I2C_SCOREBOARD__
