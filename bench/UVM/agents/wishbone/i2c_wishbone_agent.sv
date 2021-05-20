/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_wishbone_agent.sv                                       @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Agent for working with WISHBONE interface                 @
@|  Data        :  - .12.2020                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_AGENT__
`define I2C_AGENT__

///////////////////////////////////////////////////////////////////////////////
// Agent for WISHBONE interface                                              //
///////////////////////////////////////////////////////////////////////////////

class i2c_wishbone_agent extends uvm_agent;
    `uvm_component_utils(i2c_wishbone_agent)

    i2c_wb_config           i2c_wb_cfg;
    i2c_wishbone_sequencer	i2c_wb_sqncr;
    i2c_wishbone_driver     i2c_wb_driver;
    i2c_wishbone_monitor    i2c_wb_monitor;
    i2c_reg_adapter         i2c_adapter;

    function new( string name, uvm_component parent );
        super.new( name, parent );
    endfunction: new

    function void build_phase( uvm_phase phase );
        super.build_phase( phase );
        //---------------------------------------------------------------------
        GetWbCfg: assert(uvm_config_db#(i2c_wb_config)::get(
                this, "", "i2c_wb_config", i2c_wb_cfg))
        else
            `uvm_fatal(get_type_name(), "Can not find i2c_wb_cfg")
        //---------------------------------------------------------------------
        if (i2c_wb_cfg.is_active == UVM_ACTIVE) begin
            i2c_adapter = i2c_reg_adapter::type_id::create( .name( "i2c_adapter" ), .parent( this ) );
            i2c_wb_sqncr = i2c_wishbone_sequencer::type_id::create( .name( "i2c_wb_sqncr" ), .parent( this ) );
            i2c_wb_driver = i2c_wishbone_driver::type_id::create( .name( "i2c_wb_driver" ), .parent( this ) );
        end
        i2c_wb_monitor = i2c_wishbone_monitor::type_id::create( .name( "i2c_wb_monitor" ), .parent( this ) );
    endfunction: build_phase

    function void connect_phase( uvm_phase phase );
        super.connect_phase( phase );
        if (i2c_wb_cfg.is_active == UVM_ACTIVE) begin
            i2c_wb_driver.seq_item_port.connect( i2c_wb_sqncr.seq_item_export );
        end
    endfunction: connect_phase

endclass: i2c_wishbone_agent

`endif // I2C_AGENT__