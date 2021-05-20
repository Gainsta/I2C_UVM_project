module i2c_top;
//    import uvm_pkg::*;

    reg clk;
    reg rst;
    reg arst;

    i2c_wishbone_interface  i2c_wb_if(clk, rst, arst);
    i2c_serial_interface    i2c_srl_if(clk, rst, arst);
    i2c_mode_interface      i2c_mode_if();


    i2c_master_top DUT (
        .wb_clk_i       ( clk   ),
        .wb_rst_i       ( rst   ),
        .arst_i         ( arst  ),
        .wb_adr_i       ( i2c_wb_if.adr_i  ),
        .wb_dat_i       ( i2c_wb_if.dat_i  ),
        .wb_dat_o       ( i2c_wb_if.dat_o  ),
        .wb_we_i        ( i2c_wb_if.we_i   ),
        .wb_stb_i       ( i2c_wb_if.stb_i  ),
        .wb_cyc_i       ( i2c_wb_if.cyc_i  ),
        .wb_ack_o       ( i2c_wb_if.ack_o  ),
        .wb_inta_o      ( i2c_wb_if.inta_o ),
        .scl_pad_i      ( i2c_srl_if.scl_i  ),
        .scl_pad_o      ( i2c_srl_if.scl_o  ),
        .scl_padoen_o   ( i2c_srl_if.scl_en_o),
        .sda_pad_i      ( i2c_srl_if.sda_i  ),
        .sda_pad_o      ( i2c_srl_if.sda_o  ),
        .sda_padoen_o   ( i2c_srl_if.sda_en_o)
    );

initial begin
    clk = 0;
    forever begin
        #`CLK_HALF_PERIOD;
        clk = ~clk;
    end
end

initial begin
    arst = 1;
    rst = 0;
    #1;
    //after the delay send reset and arst if it needed
    if(i2c_mode_if.plus_arst) begin
        arst = 0;
        #`SYS_CLK_PERIOD;
        arst = 1;
        #`SYS_CLK_PERIOD;
        rst = 1;
        #`SYS_CLK_PERIOD;
        rst = 0;
    end else begin
        #3;
        rst = 1;
        #`SYS_CLK_PERIOD;
        rst = 0;
    end
    //after the pause send another reset if it needed
    #`SCL_DRIVE_CLK_PERIOD;
    #`SCL_DRIVE_CLK_PERIOD;
    if(i2c_mode_if.plus_rst) begin
        rst = 1;
        #`SYS_CLK_PERIOD;
        rst = 0;
    end
end

initial begin
    uvm_config_db#(i2c_wishbone_vif)::set( .cntxt( null ),
                                                .inst_name( "*.i2c_wb_agent.*" ),
                                                .field_name( "vif" ),
                                                .value( i2c_wb_if ) );
    uvm_config_db#(i2c_serial_vif)::set( .cntxt( null ),
                                                .inst_name( "*.i2c_srl_agent.*" ),
                                                .field_name( "vif" ),
                                                .value( i2c_srl_if ) );
    uvm_config_db#(i2c_mode_vif)::set( .cntxt( null ),
                                                .inst_name( "*" ),
                                                .field_name( "mode_vif" ),
                                                .value( i2c_mode_if ) );
    run_test();
end

endmodule