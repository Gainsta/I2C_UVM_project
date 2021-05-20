/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : reg_block.sv                                                @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Register block for I2C controller                         @
@|  Data        :  - .12.2020                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

// To better understand this code, see the I2C Master Core Specifications
// link: /auto/vgr/users/shpagilev_d/sector/study/labs/MCST/i2c/trunk/doc

`ifndef I2C_REG_BLOCK__
`define I2C_REG_BLOCK__

class i2c_reg_block extends uvm_reg_block;
    `uvm_object_utils( i2c_reg_block )

    rand clk_prescale_reg_lo    PRERlo;
    rand clk_prescale_reg_hi    PRERhi;
    rand control_reg            CTR;
    rand transmit_reg           TXR;
    rand receive_reg            RXR;
    rand command_reg            CR;
    rand status_reg             SR;
    uvm_reg_map                 reg_map;

    function new( string name = "i2c_reg_block" );
       super.new( .name( name ), .has_coverage( UVM_NO_COVERAGE ) );
    endfunction: new

    virtual function void build();
        PRERlo = clk_prescale_reg_lo::type_id::create( "PRERlo" );
        PRERlo.configure( .blk_parent( this ) );
        PRERlo.build();

        PRERhi = clk_prescale_reg_hi::type_id::create( "PRERhi" );
        PRERhi.configure( .blk_parent( this ) );
        PRERhi.build();

        CTR = control_reg::type_id::create( "CTR" );
        CTR.configure( .blk_parent( this ) );
        CTR.build();

        TXR = transmit_reg::type_id::create( "TXR" );
        TXR.configure( .blk_parent( this ) );
        TXR.build();

        RXR = receive_reg::type_id::create( "RXR" );
        RXR.configure( .blk_parent( this ) );
        RXR.build();

        CR = command_reg::type_id::create( "CR" );
        CR.configure( .blk_parent( this ) );
        CR.build();

        SR = status_reg::type_id::create( "SR" );
        SR.configure( .blk_parent( this ) );
        SR.build();

        reg_map = create_map( .name( "reg_map" ), .base_addr( 3'h0 ),
                                .n_bytes( 1 ), .endian( UVM_LITTLE_ENDIAN ) );
        reg_map.add_reg( .rg( PRERlo ),  .offset( 3'h0 ), .rights( "RW" ) );
        reg_map.add_reg( .rg( PRERhi ),  .offset( 3'h1 ), .rights( "RW" ) );
        reg_map.add_reg( .rg( CTR  ),    .offset( 3'h2 ), .rights( "RW" ) );
        reg_map.add_reg( .rg( TXR  ),    .offset( 3'h3 ), .rights( "WO" ) );
        reg_map.add_reg( .rg( RXR  ),    .offset( 3'h3 ), .rights( "RO" ) );
        reg_map.add_reg( .rg( CR  ),     .offset( 3'h4 ), .rights( "WO" ) );
        reg_map.add_reg( .rg( SR  ),     .offset( 3'h4 ), .rights( "RO" ) );
        lock_model(); // finalize the address mapping

    endfunction: build
endclass: i2c_reg_block

`endif // I2C_REG_BLOCK__