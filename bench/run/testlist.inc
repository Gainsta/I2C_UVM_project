# vim: set ft=make:

TESTS_ALL = \
            i2c_base_test                   \
            i2c_check_test                  \
            i2c_reg_hw_reset_test           \
            i2c_reg_bit_bash_seq            \
            i2c_single_write_test           \
            i2c_single_read_test            \
            i2c_multiple_write_test         \
            i2c_multidirectional_write_test \
            i2c_multiple_read_test          \
            i2c_multidirectional_read_test  \
            i2c_multidirectional_rw_test    \
            i2c_PREP_test                   \
            i2c_slave_busy_adr_test         \
            i2c_slave_busy_dat_test         \
            i2c_arbitration_lost_test       \
            i2c_multidirectional_rw_IEN_test\
            i2c_single_read_with_rst_test
