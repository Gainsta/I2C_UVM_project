/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_seria_agent.sv                                          @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Agent for working with SERIAL interface                   @
@|  Data        :  - .02.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_SERIAL_AGENT__
`define I2C_SERIAL_AGENT__

///////////////////////////////////////////////////////////////////////////////
// Agent for SERIAL interface                                                //
///////////////////////////////////////////////////////////////////////////////

class i2c_serial_agent extends uvm_agent;
    `uvm_component_utils(i2c_serial_agent)

    i2c_srl_config          i2c_srl_cfg;
    i2c_serial_sequencer    i2c_srl_sqncr;
    i2c_serial_driver       i2c_srl_driver;
    i2c_serial_monitor      i2c_srl_monitor;

    function new( string name, uvm_component parent );
        super.new( name, parent );
    endfunction: new

    function void build_phase( uvm_phase phase );
        super.build_phase( phase );
        //---------------------------------------------------------------------
        GetSrlCfg: assert(uvm_config_db#(i2c_srl_config)::get(this, "", "i2c_srl_config", i2c_srl_cfg))
        else
            `uvm_fatal(get_type_name(), "Can not find i2c_srl_cfg")
        //---------------------------------------------------------------------
        if (i2c_srl_cfg.is_active == UVM_ACTIVE) begin
            i2c_srl_driver = i2c_serial_driver::type_id::create( .name( "i2c_srl_driver" ), .parent( this ) );
        end
        i2c_srl_monitor = i2c_serial_monitor::type_id::create( .name( "i2c_srl_monitor" ), .parent( this ) );
    endfunction: build_phase

    function void connect_phase( uvm_phase phase );
        super.connect_phase( phase );
    endfunction: connect_phase

endclass: i2c_serial_agent

`endif // I2C_SERIAL_AGENT__