/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@|  File name   : i2c_serial_sequencer.sv                                     @
@|  Project     : I2C_test                                                   @
@|  Created     : Nikolay Dvoynishnikov                                     @
@|  Description : Sequencer for SERIAL agent                                @
@|  Data        :  - .02.2021                                                @
@|  Notes       :                                                             @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

`ifndef I2C_SERIAL_SEQUENCER__
`define I2C_SERIAL_SEQUENCER__

typedef uvm_sequencer#(i2c_transfer_item) i2c_serial_sequencer;

`endif //I2C_SERIAL_SEQUENCER__