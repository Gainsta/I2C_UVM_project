/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_env.sv                                                  @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Environment for I2C controller                            @
@|  Data        :  - .02.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_ENVIRONMENT__
`define I2C_ENVIRONMENT__

class i2c_environment extends uvm_env;
    `uvm_component_utils( i2c_environment )

    typedef uvm_reg_predictor#( i2c_wishbone_item ) i2c_reg_predictor;

    i2c_config          i2c_env_cfg;
    i2c_reg_block       i2c_mem_block;
    i2c_wishbone_agent  i2c_wb_agent;
    i2c_serial_agent    i2c_srl_agent;
    i2c_reg_predictor   i2c_predictor;
    i2c_scoreboard      i2c_sb;
    i2c_mode_vif        i2c_mode_if;

    function new( string name, uvm_component parent );
        super.new( name, parent );
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //---------------------------------------------------------------------
        GetEnvCfg: assert(uvm_config_db#(i2c_config)::get(
                this, "", "i2c_env_cfg", i2c_env_cfg))
        else
            `uvm_fatal(get_type_name(), "Can not find i2c_env_cfg")
        //---------------------------------------------------------------------
        GetModVif: assert(uvm_config_db#(i2c_mode_vif)::get(
                this, "", "mode_vif", i2c_mode_if))
        else
            `uvm_fatal(get_type_name(), "Can not find i2c_mode_if")
        //---------------------------------------------------------------------
        i2c_wb_agent = i2c_wishbone_agent::type_id::create( .name( "i2c_wb_agent" ), .parent( this ));
        i2c_srl_agent = i2c_serial_agent::type_id::create( .name( "i2c_srl_agent" ), .parent( this ));
        i2c_predictor = i2c_reg_predictor::type_id::create( .name("i2c_predictor"), .parent(this));
        i2c_sb = i2c_scoreboard::type_id::create( .name("i2c_sb"), .parent(this));
        //---------------------------------------------------------------------
        GetMemBlock: assert(uvm_config_db#(i2c_reg_block)::get(
                this, "", "reg_block", i2c_mem_block))
        else
            `uvm_fatal(get_type_name(), "Can not find i2c_mem_block")
        //---------------------------------------------------------------------
        uvm_config_db#(i2c_wb_config)::set(this, "i2c_wb_agent", "i2c_wb_config", i2c_env_cfg.i2c_wb_cfg);
        uvm_config_db#(i2c_srl_config)::set(this, "i2c_srl_agent", "i2c_srl_config", i2c_env_cfg.i2c_srl_cfg);

    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        i2c_mem_block.reg_map.set_sequencer( .sequencer(i2c_wb_agent.i2c_wb_sqncr), .adapter(i2c_wb_agent.i2c_adapter) );
        i2c_mem_block.reg_map.set_auto_predict(0);
        i2c_predictor.map = i2c_mem_block.reg_map;
        i2c_predictor.adapter = i2c_wb_agent.i2c_adapter;

        // Set mode_if accordingly with config file
        i2c_mode_if.plus_rst = i2c_env_cfg.plus_rst;
        i2c_mode_if.plus_arst = i2c_env_cfg.plus_arst;

        // Connect analysis port
        i2c_wb_agent.i2c_wb_sqncr.wb_item_wr_port.connect(i2c_sb.wishbone_write);
        i2c_wb_agent.i2c_wb_monitor.wb_item_rd_port.connect(i2c_sb.wishbone_read);
        i2c_wb_agent.i2c_wb_monitor.wb_item_dnd_port.connect(i2c_sb.wishbone_denied);
        i2c_srl_agent.i2c_srl_monitor.srl_item_wr_port.connect(i2c_sb.serial_write);
        i2c_srl_agent.i2c_srl_monitor.srl_item_rd_port.connect(i2c_sb.serial_read);
        i2c_srl_agent.i2c_srl_monitor.srl_item_dnd_port.connect(i2c_sb.serial_denied);

        // Send configuration data to serial driver
        i2c_srl_agent.i2c_srl_driver.scl_drive_clk_half_period = i2c_env_cfg.scl_drive_clk_half_period;
        i2c_srl_agent.i2c_srl_driver.scl_drive_clk_quarter_period = i2c_env_cfg.scl_drive_clk_quarter_period;
        i2c_srl_agent.i2c_srl_driver.slave_busy_addr = i2c_env_cfg.slave_busy_addr;
        i2c_srl_agent.i2c_srl_driver.slave_busy_data = i2c_env_cfg.slave_busy_data;
        i2c_srl_agent.i2c_srl_driver.arbitration_lost = i2c_env_cfg.arbitration_lost;
    endfunction: connect_phase

 endclass: i2c_environment

 `endif // I2C_ENVIRONMENT__