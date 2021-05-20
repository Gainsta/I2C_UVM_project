/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_interface.sv                                            @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Interface for I2C controller                              @
@|  Data        :  - .11.2020                                                @
@|  Notes                                                                     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_IF__
`define I2C_IF__

///////////////////////////////////////////////////////////////////////////////
// Interface for WISHBONE signals                                            //
///////////////////////////////////////////////////////////////////////////////

interface i2c_wishbone_interface #( LOW_ADDR_BITS = `LOW_ADDR_WIDTH,
                                    DATABUS_WIDTH = `DATABUS_WIDTH)
    (
        input logic   clk,   // master clock input
        input logic   rst,   // synchronous active high reset
        input logic   arst   // asynchronous reset
    );

    logic [LOW_ADDR_BITS-1:0]   adr_i;       // lower address bits
    logic [DATABUS_WIDTH-1:0]   dat_i;       // databus input
    logic [DATABUS_WIDTH-1:0]   dat_o;       // databus output
    logic                       we_i;        // write enable input
    logic                       stb_i;       // stobe/core select signal
    logic                       cyc_i;       // valid bus cycle input
    logic                       ack_o;       // bus cycle acknowledge output
    logic                       inta_o;      // interrupt request signal output

    logic is_assert_checks = `IS_ASSERT_CHECKS_WB;

    //---------------------------------------------------
    // Properties
    //---------------------------------------------------

    property adr_i_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !$isunknown(adr_i);
    endproperty

    property dat_i_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !$isunknown(dat_i);
    endproperty

    property we_i_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !$isunknown(we_i);
    endproperty

    property stb_i_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !$isunknown(stb_i);
    endproperty

    property cyc_i_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !$isunknown(cyc_i);
    endproperty

    property notRW;
        disable iff(!is_assert_checks)
        @(posedge clk) (adr_i == 3'b100) |-> (dat_i[7:6] != 2'b11);
    endproperty

    //---------------------------------------------------
    // Assertions
    //---------------------------------------------------

    adr_i_nox_a:
        assert property(adr_i_nox)
        else
            $fatal("incorrect data (x or z) on wire adr_i = %b", adr_i);

    dat_i_nox_a:
        assert property(dat_i_nox)
        else
            $fatal("incorrect data (x or z) on wire dat_i");

    we_i_nox_a:
        assert property(we_i_nox)
        else
            $fatal("incorrect data (x or z) on wire we_i");

    stb_i_nox_a:
        assert property(stb_i_nox)
        else
            $fatal("incorrect data (x or z) on wire stb_i");

    cyc_i_nox_a:
        assert property(cyc_i_nox)
        else
            $fatal("incorrect data (x or z) on wire cyc_i");

    notRW_a:
        assert property(notRW)
        else
            $error("In comand reg R and W can't be 1 at the same time");

endinterface : i2c_wishbone_interface

typedef virtual interface i2c_wishbone_interface i2c_wishbone_vif;

///////////////////////////////////////////////////////////////////////////////
// Interface for external connections                                        //
///////////////////////////////////////////////////////////////////////////////

interface i2c_serial_interface(
    input logic   clk,   // master clock input
    input logic   rst,   // synchronous active high reset
    input logic   arst   // asynchronous reset
);
    logic   scl_i;      // SCL-line input
    logic   scl_o;      // SCL-line output (always 1'b0)
    logic   scl_en_o;   // SCL-line output enable (active low)
    logic   sda_i;      // SDA-line input
    logic   sda_o;      // SDA-line output (always 1'b0)
    logic   sda_en_o;   // SDA-line output enable (active low)
    logic   SCL;
    logic   SDA;

    logic is_assert_checks = `IS_ASSERT_CHECKS_SRL;

    assign SCL = scl_i & scl_en_o;
    assign SDA = sda_i & sda_en_o;

    //---------------------------------------------------
    // Properties
    //---------------------------------------------------

    property sda_en_o_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !($isunknown(sda_en_o) & (!rst));
    endproperty

    property sda_o_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !$isunknown(sda_o);
    endproperty

    property scl_en_o_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !($isunknown(scl_en_o) & (!rst));
    endproperty

    property scl_o_nox;
        disable iff(!is_assert_checks)
        @(posedge clk) !$isunknown(scl_o);
    endproperty

    //---------------------------------------------------
    // Assertions
    //---------------------------------------------------

    sda_en_o_nox_a:
        assert property(sda_en_o_nox)
        else
            $fatal("incorrect data (x or z) on wire sda_en_o");

    sda_o_nox_a:
        assert property(sda_o_nox)
        else
            $fatal("incorrect data (x or z) on wire sda_o");

    scl_en_o_nox_a:
        assert property(scl_en_o_nox)
        else
            $fatal("incorrect data (x or z) on wire scl_en_o");

    scl_o_nox_a:
        assert property(scl_o_nox)
        else
            $fatal("incorrect data (x or z) on wire scl_o");

endinterface : i2c_serial_interface

typedef virtual interface i2c_serial_interface i2c_serial_vif;

///////////////////////////////////////////////////////////////////////////////
// Interface for change work mode                                            //
///////////////////////////////////////////////////////////////////////////////

interface i2c_mode_interface();

    logic   plus_arst;      // use areset in the start of the test
    logic   plus_rst;       // plus one reset during the test

endinterface : i2c_mode_interface

typedef virtual interface i2c_mode_interface i2c_mode_vif;

`endif // I2C_IF__