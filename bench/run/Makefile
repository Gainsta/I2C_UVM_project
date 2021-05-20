# vim: set ft=make

PROJECT					= I2C_Test
DEVICE					= I2C_Master

####################################
##          Run options            |
####################################

MODE				= DEBUG
DUMP				= OFF
GUI					= OFF
LINT				= OFF
VERDI				= OFF

####################################
##         VCS variables           |
####################################

VCS_MODE			= 2019
ifeq ($(VCS_MODE), 2013)
	VCS_VER				= vcs_mx_vH-2013.06
	SET_LM_LICENSE		= source /auto/vgr/tools/lmlicenserc.bash
endif
ifeq ($(VCS_MODE), 2016)
	VCS_VER				= vL-2016.06
	SET_LM_LICENSE		= export LM_LICENSE_FILE=27000@astro-33:27000@astro-34:27000@bard:27000@whale:27000@loot:27000@mammoth:27000@bugor:27000@venaja
endif
ifeq ($(VCS_MODE), 2017_03)
	VCS_VER				= vM-2017.03-SP1-1
	SET_LM_LICENSE		= export LM_LICENSE_FILE=27000@astro-34:27000@bard:27000@whale:27000@loot:27000@mammoth:27000@bugor:27000@venaja
endif
ifeq ($(VCS_MODE), 2017)
	VCS_VER				= vN-2017.12
	SET_LM_LICENSE		= source /auto/vgr/tools/lmlicenserc.bash
endif
ifeq ($(VCS_MODE), 2018)
	VCS_VER				= vcs-mx_vO-2018.09-SP1
	SET_LM_LICENSE		= source /auto/vgr/tools/lmlicenserc.bash
endif
ifeq ($(VCS_MODE), 2019)
	VCS_VER				= vcs_vP-2019.06-SP2_1
	SET_LM_LICENSE		= source /auto/vgr/tools/lmlicenserc-2019.bash
endif
##-------------------------------------------------------------
export VCS_HOME		= /auto/da/cad/synopsys/VCS/$(VCS_VER)
export UVM_HOME		= /auto/vgr/uvm/uvm-1.2
##-------------------------------------------------------------
VCS					:= $(SET_LM_LICENSE); $(VCS_HOME)/bin/vcs
SIMV				:= $(SET_LM_LICENSE); ./simv
UVM_INCDIR			:= +incdir+$(UVM_HOME)/src
BUILD_OPTS 			+= -full64

####################################
##      Main path variables        |
####################################

##	стандартный путь получения - добавляем ../ от точки Makefile'а
export BENCH_HOME			:= $(dir $(lastword $(MAKEFILE_LIST)))/..
export RTL_PATH				:= $(I2C_PATH)/rtl/verilog
export DEVICE_TB_TOP		:= $(RTL_PATH)/i2c_master_top.v
##-------------------------------------------------------------
##	путь для сохранения базы данных покрытия
COV_PATH			?= $(BENCH_HOME)/COV
COVER_SUFFIX		= $(DEVICE).$@_$(JOB_ID)_$(SGE_TASK_ID)
##-------------------------------------------------------------
##  SGE (Grid) variables
SGE_TASK_ID			?= 1
JOD_ID				?= 0
##-------------------------------------------------------------
##	UVM test variables
SEED				= random
VERBOSITY			= UVM_MEDIUM
TIMEOUT				= 800000

RUN_NAME			= simv.$(DEVICE)
INTERNAL_DEFINES	= +define+
LOG_NAME			= i2c_tests

##-------------------------------------------------------------
##  VLOG.OPT files
VLOG_OPTS += -f $(BENCH_HOME)/testbench/vlog.opt


## List of UVM testnames
-include $(BENCH_HOME)/run/testlist.inc

####################################
##          CONDITIONS             |
####################################
##-------------------------------------------------------------
ifeq ($(MODE), COMMON)
	DUMP		= OFF
	VERBOSITY	= UVM_LOW
endif
# Debug mode options
ifeq ($(MODE), DEBUG)
	ARCH_OPTS	+= -debug_all
endif
# Coverage mode options
ifeq ($(MODE), COVER)
	ARCH_OPTS	+=	-debug_all								\
					-cm_dir $(COV_PATH)						\
					-cm line+cond+branch
	COVER_SETUP	+=	-cm_name $(COVER_SUFFIX)				\
					-cm line+cond+branch
endif
##-------------------------------------------------------------
ifeq ($(DUMP), ON)
	ARCH_OPTS	+=	+define+DEBUG_MODE			\
					+memcbk						\
					+v2k
endif
##-------------------------------------------------------------
ifeq ($(GUI), ON)
	MAKE_RUN_OPTS	+= -gui
	MAKE_RUN_OPTS	+= -dve_opt -cmd=run
endif
##-------------------------------------------------------------
##-------------------------------------------------------------
ifeq ($(VERBOSITY), UVM_DEBUG)
	MAKE_RUN_OPTS	+=	+UVM_OBJECTION_TRACE	\
						+UVM_PHASE_TRACE		\
						+UVM_CONFIG_DB_TRACE
endif
##-------------------------------------------------------------
ifeq ($(LINT), ON)
	LINT_OPTS		+= +lint=all,noIWU,noNS
endif
##-------------------------------------------------------------

####################################
##         SEED variable           |
####################################
ifeq ($(SEED), random)
	TEST_SETUP += +ntb_random_seed_automatic
else
	TEST_SETUP += +ntb_random_seed=$(SEED)
endif

####################################
##            DEFINES              |
####################################
UVM_DEFINES			:= +define+UVM_NO_DEPRECATED

####################################
##            TARGETS              |
####################################
BUILD_COMMAND	=	\
	$(VCS)								\
	$(UVM_INCDIR)						\
	$(ARCH_OPTS)						\
	$(BUILD_OPTS)						\
	$(LINT_OPTS)						\
	$(UVM_DEFINES)						\
	$(INTERNAL_DEFINES)					\
	-l COMP.$(RUN_NAME).log				\
	+v2k								\
	+nospecify							\
	+notimingchecks						\
	-timescale=1ns/10ps					\
	+libext+.v							\
	-CFLAGS '-DVCS'						\
	+systemverilogext+sv				\
	+sverilog							\
	+vcs+loopdetect						\
	+vcs+lic+wait						\
	$(UVM_HOME)/src/dpi/uvm_dpi.cc		\
	$(VLOG_OPTS);

RUN_COMMAND	=	\
	$(SIMV)								\
	+UVM_TIMEOUT=$(TIMEOUT)				\
	+UVM_TESTNAME=$@					\
	+UVM_VERBOSITY=$(VERBOSITY)			\
	+UVM_NO_RELNOTES					\
	-l $(LOG_NAME).log					\
	$(VCS_SET_SEED)						\
	$(TEST_SETUP)						\
	$(COVER_SETUP)						\
	$(MAKE_RUN_OPTS)					\
	$(RUN_OPTS);

####################################
##             RULES               |
####################################

##-------------------------------------------------------------
# Compilation
##-------------------------------------------------------------
build:
	$(BUILD_COMMAND)

##-------------------------------------------------------------
# Run test
##-------------------------------------------------------------

$(TESTS_ALL): build
	$(RUN_COMMAND)

##-------------------------------------------------------------
# Clean directory
##-------------------------------------------------------------
.PHONY: clean
clean:
	$(RM) -r inter.vpd COMP.$(RUN_NAME).log  csrc  DVEfiles  simv  simv.daidir  tr_db.log  ucli.key  vc_hdrs.h $(LOG_NAME).log

##-------------------------------------------------------------
# Create local coverage report (сбор покрытия без исключений)
##-------------------------------------------------------------
cover_report:
	$(SET_LM_LICENSE);											\
	VCS_HOME=$(VCS_HOME) PROJECT=$(PROJECT) DEVICE=$(DEVICE)	\
	$(VCS_HOME)/bin/urg											\
	-dir $(COV_PATH).vdb										\
	-report $(COV_PATH).vdb/../report

##-------------------------------------------------------------
# Create local coverage report with exclusions (сбор покрытия с исключениями)
##-------------------------------------------------------------
excl_cover_report:
	$(SET_LM_LICENSE);											\
	VCS_HOME=$(VCS_HOME) PROJECT=$(PROJECT) DEVICE=$(DEVICE)	\
	$(VCS_HOME)/bin/urg											\
	-dir $(COV_PATH).vdb										\
	-elfile $(BENCH-HOME)/run/$(PROJECT)_$(DEVICE)_excl.el		\
	-report $(COV_PATH).vdb/../report

##-------------------------------------------------------------
# View coverage in DVE
##-------------------------------------------------------------
cover_view:
	$(SET_LM_LICENSE);											\
	VCS_HOME=$(VCS_HOME)										\
	$(VCS_HOME)/bin/dve -covdir $(COV_PATH).vdb

##-------------------------------------------------------------
# Create coverage database
##-------------------------------------------------------------
db:
	$(VCS_HOME)/bin/urg -dir ./simv.vdb -dbname ./coverage/test_db

##-------------------------------------------------------------
# Create global coverage report
##-------------------------------------------------------------
report:
	$(VCS_HOME)/bin/urg -dir ./coverage.vdb -report ./cov_report

##-------------------------------------------------------------
# Print Testlist
##-------------------------------------------------------------
show:
	@echo 'Available tests:'
	@echo '    $(TESTS_ALL) '

tests: show

##-------------------------------------------------------------
# Print info
##-------------------------------------------------------------
info:
	@echo '*** Environment variables ***'
	@echo 'VCS_VER      = $(VCS_VER)'
	@echo 'VCS_HOME     = $(VCS_HOME)'
	@echo
	@echo '*** Main path variables ***'
	@echo 'BENCH_HOME   = $(BENCH_HOME)'
	@echo 'RTL_PATH     = $(RTL_PATH)'
	@echo
	@echo '*** UVM test variables ***'
	@echo 'TESTNAME     = $(TESTNAME)'
	@echo 'TESTSETUP    = $(TEST_SETUP)'
	@echo 'SEED         = $(SEED)'
	@echo 'VERBOSITY    = $(VERBOSITY)'
	@echo 'DEFINES      = $(INTERNAL_DEFINES)'
	@echo
	@echo '*** Project specific variables ***'
	@echo ''

##-------------------------------------------------------------
# Available Commands
##-------------------------------------------------------------
help:
	@echo '*-------------------------------------------------------------*'
	@echo '|                   ***      Help     ***                     |'
	@echo '*-------------------------------------------------------------*'
	@echo '|  clean          - очисть директорию                         |'
	@echo '|  build          - компиляция                                |'
	@echo '|  tests          - список всех доступных тестов              |'
	@echo '|  <testname>     - запуск теста <testname>                   |'
	@echo '*-------------------------------------------------------------*'
