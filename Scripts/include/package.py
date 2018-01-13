
"""
Constant declarations
"""
# Root directory
import os

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))[:-16]


# Better safe than sorry
os.chdir(PROJECT_ROOT)

# Temporary directory for storing simulation files
TMP_DIR = PROJECT_ROOT + "/tmp"
SIMUL_DIR = TMP_DIR + "/simul_temp"
LOG_DIR = SIMUL_DIR+ "/logs"
TRACE_DIR = SIMUL_DIR+ "/traces"

# Subfolders
SCRIPTS_DIR = PROJECT_ROOT + "/Scripts"
ROUTER_RTL_DIR = PROJECT_ROOT+"/RTL/base_line"
ROUTER_VC_RTL_DIR = PROJECT_ROOT+"/RTL/virtual_channel"
TEST_DIR = PROJECT_ROOT + "/Packages"


# Flow control suffixes
CREDIT_BASED_SUFFIX = "credit_based"

# Script names
NET_GEN_SCRIPT = "network_gen_parameterized"
NET_TB_GEN_SCRIPT = "network_tb_gen_parameterized"
WAVE_DO_GEN_SCRIPT = "wave_do_gen"
SIMUL_DO_SCRIPT = "simulate.do"
RECEIVED_TXT_PATH = "received.txt"
SENT_TXT_PATH = "sent.txt"
LATENCY_CALCULATION_PATH = "calculate_latency.py"

# Default simulation configuration
program_argv = {
        'network_dime_x':     4,
        'network_dime_y':     4,
        'vc':                -1,
        'rand':              -1,
        'BR':                -1,
        'PS':                [3,8],
        'sim':               -1,
        'end':               -1,
        'lat':               False,
        'debug':             False,
        'trace':             False,
        'command-line':      False,
    }

# Debug mode is off by default
DEBUG = False
