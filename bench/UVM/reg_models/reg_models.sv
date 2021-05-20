/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : reg_models.sv                                               @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Register models for I2C controller                        @
@|  Data        :  - .01.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

// To better understand this code, see the I2C Master Core Specifications
// link: /auto/vgr/users/shpagilev_d/sector/study/Labs/MCST/i2c/trunk/doc

`ifndef I2C_REG_MODEL__
`define I2C_REG_MODEL__

///////////////////////////////////////////////////////////////////////////////
// Prescale register low                                                     //
///////////////////////////////////////////////////////////////////////////////

class clk_prescale_reg_lo extends uvm_reg;
    `uvm_object_utils( clk_prescale_reg_lo )

    rand uvm_reg_field prescale;

    function new( string name = "clk_prescale_reg_lo" );
       super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
    endfunction: new

    virtual function void build();
        prescale = uvm_reg_field::type_id::create( "prescale" );
        prescale.configure( .parent                 ( this ),
                            .size                   ( 8    ),
                            .lsb_pos                ( 0    ),
                            .access                 ( "RW" ),
                            .volatile               ( 0    ),
                            .reset                  ( 8'hFF),
                            .has_reset              ( 1    ),
                            .is_rand                ( 1    ),
                            .individually_accessible( 1    ) );

    endfunction: build
endclass: clk_prescale_reg_lo

///////////////////////////////////////////////////////////////////////////////
// Prescale register high                                                    //
///////////////////////////////////////////////////////////////////////////////

class clk_prescale_reg_hi extends uvm_reg;
    `uvm_object_utils( clk_prescale_reg_hi )

    rand uvm_reg_field prescale;

    function new( string name = "clk_prescale_reg_hi" );
       super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
    endfunction: new

    virtual function void build();
        prescale = uvm_reg_field::type_id::create( "prescale" );
        prescale.configure( .parent                 ( this ),
                            .size                   ( 8    ),
                            .lsb_pos                ( 0    ),
                            .access                 ( "RW" ),
                            .volatile               ( 0    ),
                            .reset                  ( 8'hFF),
                            .has_reset              ( 1    ),
                            .is_rand                ( 1    ),
                            .individually_accessible( 1    ) );

    endfunction: build
endclass: clk_prescale_reg_hi

///////////////////////////////////////////////////////////////////////////////
// Control register                                                          //
///////////////////////////////////////////////////////////////////////////////

class control_reg extends uvm_reg;
    `uvm_object_utils( control_reg )

    rand uvm_reg_field EN;
    rand uvm_reg_field IEN;
    rand uvm_reg_field Reserved;

    function new( string name = "control_reg" );
       super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
    endfunction: new

    virtual function void build();
        Reserved = uvm_reg_field::type_id::create( "Reserved" );
        Reserved.configure( .parent                 ( this ),
                            .size                   ( 6    ),
                            .lsb_pos                ( 0    ),
                            .access                 ( "RW" ),
                            .volatile               ( 0    ),
                            .reset                  ( 6'h00),
                            .has_reset              ( 1    ),
                            .is_rand                ( 1    ),
                            .individually_accessible( 0    ) );

        IEN = uvm_reg_field::type_id::create( "IEN" );
        IEN.configure(  .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 6    ),
                        .access                 ( "RW" ),
                        .volatile               ( 0    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        EN = uvm_reg_field::type_id::create( "EN" );
        EN.configure(   .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 7    ),
                        .access                 ( "RW" ),
                        .volatile               ( 0    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

    endfunction: build
endclass: control_reg

///////////////////////////////////////////////////////////////////////////////
// Transmit register                                                         //
///////////////////////////////////////////////////////////////////////////////

class transmit_reg extends uvm_reg;
    `uvm_object_utils( transmit_reg )

    rand uvm_reg_field nextByte;
    rand uvm_reg_field LSB;

    function new( string name = "transmit_reg" );
        super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
    endfunction: new

    virtual function void build();
        LSB = uvm_reg_field::type_id::create( "LSB" );
        LSB.configure(  .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 0    ),
                        .access                 ( "WO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        nextByte = uvm_reg_field::type_id::create( "nextByte" );
        nextByte.configure(    .parent                 ( this ),
                                .size                   ( 7    ),
                                .lsb_pos                ( 1    ),
                                .access                 ( "WO" ),
                                .volatile               ( 1    ),
                                .reset                  ( 1'b0 ),
                                .has_reset              ( 1    ),
                                .is_rand                ( 1    ),
                                .individually_accessible( 1    ) );

    endfunction: build
endclass: transmit_reg

///////////////////////////////////////////////////////////////////////////////
// Recieve register                                                          //
///////////////////////////////////////////////////////////////////////////////

class receive_reg extends uvm_reg;
    `uvm_object_utils( receive_reg )

    rand uvm_reg_field lastByte;

    function new( string name = "receive_reg" );
        super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
    endfunction: new

    virtual function void build();
        lastByte = uvm_reg_field::type_id::create( "lastByte" );
        lastByte.configure(     .parent                 ( this ),
                                .size                   ( 8    ),
                                .lsb_pos                ( 0    ),
                                .access                 ( "RO" ),
                                .volatile               ( 1    ),
                                .reset                  ( 1'b0 ),
                                .has_reset              ( 1    ),
                                .is_rand                ( 1    ),
                                .individually_accessible( 0    ) );

    endfunction: build
endclass: receive_reg

///////////////////////////////////////////////////////////////////////////////
// Comand register                                                           //
///////////////////////////////////////////////////////////////////////////////

class command_reg extends uvm_reg;
    `uvm_object_utils( command_reg )

    rand uvm_reg_field STA;
    rand uvm_reg_field STO;
    rand uvm_reg_field RD;
    rand uvm_reg_field WR;
    rand uvm_reg_field ACK;
    rand uvm_reg_field Reserved;
    rand uvm_reg_field IACK;

    function new( string name = "command_reg" );
        super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
    endfunction: new

    virtual function void build();
        STA = uvm_reg_field::type_id::create( "STA" );
        STA.configure(  .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 7    ),
                        .access                 ( "WO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        STO = uvm_reg_field::type_id::create( "STO" );
        STO.configure(  .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 6    ),
                        .access                 ( "WO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        RD = uvm_reg_field::type_id::create( "RD" );
        RD.configure(   .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 5    ),
                        .access                 ( "WO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        WR = uvm_reg_field::type_id::create( "WR" );
        WR.configure(   .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 4    ),
                        .access                 ( "WO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        ACK = uvm_reg_field::type_id::create( "ACK" );
        ACK.configure(  .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 3    ),
                        .access                 ( "WO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        Reserved = uvm_reg_field::type_id::create( "Reserved" );
        Reserved.configure(  .parent            ( this ),
                        .size                   ( 2    ),
                        .lsb_pos                ( 1    ),
                        .access                 ( "WO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 0    ) );

        IACK = uvm_reg_field::type_id::create( "IACK" );
        IACK.configure( .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 0    ),
                        .access                 ( "WO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

    endfunction: build
endclass: command_reg

///////////////////////////////////////////////////////////////////////////////
// Status register                                                           //
///////////////////////////////////////////////////////////////////////////////

class status_reg extends uvm_reg;
    `uvm_object_utils( status_reg )

    rand uvm_reg_field RxACK;
    rand uvm_reg_field busy;
    rand uvm_reg_field AL;
    rand uvm_reg_field Reserved;
    rand uvm_reg_field TIP;
    rand uvm_reg_field IF;

    function new( string name = "status_reg" );
        super.new( .name( name ), .n_bits( 8 ), .has_coverage( UVM_NO_COVERAGE ) );
    endfunction: new

    virtual function void build();
        RxACK = uvm_reg_field::type_id::create( "RxACK" );
        RxACK.configure(.parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 7    ),
                        .access                 ( "RO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        busy = uvm_reg_field::type_id::create( "busy" );
        busy.configure( .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 6    ),
                        .access                 ( "RO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        AL = uvm_reg_field::type_id::create( "AL" );
        AL.configure(   .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 5    ),
                        .access                 ( "RO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        Reserved = uvm_reg_field::type_id::create( "Reserved" );
        Reserved.configure(.parent              ( this ),
                        .size                   ( 3    ),
                        .lsb_pos                ( 2    ),
                        .access                 ( "RO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 0    ) );

        TIP = uvm_reg_field::type_id::create( "TIP" );
        TIP.configure(  .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 1    ),
                        .access                 ( "RO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

        IF = uvm_reg_field::type_id::create( "IF" );
        IF.configure(   .parent                 ( this ),
                        .size                   ( 1    ),
                        .lsb_pos                ( 0    ),
                        .access                 ( "RO" ),
                        .volatile               ( 1    ),
                        .reset                  ( 1'b0 ),
                        .has_reset              ( 1    ),
                        .is_rand                ( 1    ),
                        .individually_accessible( 1    ) );

    endfunction: build
endclass: status_reg

`endif // I2C_REG_MODEL__