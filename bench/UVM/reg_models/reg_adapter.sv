/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : reg_adapter.sv                                              @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Adapter for rgister block and I2C controller              @
@|  Data        :  - .12.2020                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_REG_ADAPTER__
`define I2C_REG_ADAPTER__

class i2c_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils( i2c_reg_adapter )

    function new(string name = "i2c_reg_adapter");
        super.new(name);
        supports_byte_enable = 0;
        provides_responses = 0;
    endfunction

    virtual function uvm_sequence_item reg2bus (const ref uvm_reg_bus_op rw);
        i2c_wishbone_item item = i2c_wishbone_item#()::type_id::create("item");
        item.we = (rw.kind == UVM_READ) ? 0 : 1;
        item.addr = rw.addr;
        item.data_i = rw.data;
        return item;
    endfunction: reg2bus

    virtual function void bus2reg (uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        i2c_wishbone_item item;
        if(!$cast(item, bus_item)) begin
            `uvm_fatal("NOT_ITEM_TYPE", "Provided item is not of the correct type")
            return;
        end
        rw.kind = item.we ? UVM_WRITE : UVM_READ;
        rw.addr = item.addr;
        rw.data = item.data_o;
        rw.status = UVM_IS_OK;
    endfunction: bus2reg
endclass: i2c_reg_adapter

`endif // I2C_REG_ADAPTER__