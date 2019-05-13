# Copyright (C) 2016 Siavoosh Payandeh Azad

import sys

from ACII_art import generate_ascii_art
from CB_compoments import declare_components
from CB_FC_Package import CreditBasedPackage
from Instantiate_components import instantiate_routers
from network_entity import generate_entity
from Signal_declaration import declare_signals

CB_Package = CreditBasedPackage()
if CB_Package.sort_out_parameters(sys.argv[1:]):
    sys.exit()

CB_Package.parameters_sanity_check()
file_path = CB_Package.generate_file_name(sys.argv[1:])

noc_file = open(file_path, 'w')

noc_file.write("--Copyright (C) 2016 Siavoosh Payandeh Azad\n")
noc_file.write("------------------------------------------------------------\n")
noc_file.write("-- This file is automatically generated!\n")
noc_file.write("-- Here are the parameters:\n")
noc_file.write("-- \t network size x: " + str(CB_Package.network_dime_x) + "\n")
noc_file.write("-- \t network size y: " + str(CB_Package.network_dime_y) + "\n")
noc_file.write("-- \t Data width: " + str(CB_Package.data_width) + "\n")
noc_file.write("------------------------------------------------------------\n\n")

noc_file.write("library ieee;\n")
noc_file.write("use ieee.std_logic_1164.all;\n")
noc_file.write("use IEEE.STD_LOGIC_ARITH.ALL;\n")
noc_file.write("use IEEE.STD_LOGIC_UNSIGNED.ALL;\n")
noc_file.write("USE ieee.numeric_std.ALL; \n")
noc_file.write("\n")

generate_entity(noc_file, CB_Package.network_dime_x, CB_Package.network_dime_y, CB_Package.vc)

noc_file.write("\n\n")
noc_file.write("architecture behavior of network_" +
               str(CB_Package.network_dime_x) + "x" + str(CB_Package.network_dime_y) + " is\n\n")

# declaring components, signals and making ascii art!!!
declare_components(noc_file, CB_Package.vc)
declare_signals(noc_file, CB_Package.network_dime_x, CB_Package.network_dime_y, CB_Package.vc)
generate_ascii_art(noc_file, CB_Package.network_dime_x, CB_Package.network_dime_y)


noc_file.write("begin\n\n\n")
instantiate_routers(noc_file, CB_Package.network_dime_x, CB_Package.network_dime_y, CB_Package.vc)

noc_file.write(
    "---------------------------------------------------------------\n")
noc_file.write("-- binding the routers together\n")
noc_file.write("-- vertical ins/outs\n")

for i in range(CB_Package.network_dime_x * CB_Package.network_dime_y):
    node_x = int(i % CB_Package.network_dime_x)
    node_y = int(i / CB_Package.network_dime_x)
    if node_y != CB_Package.network_dime_y - 1:
        noc_file.write("-- connecting router: " + str(i) + " to router: " +
                       str(i + CB_Package.network_dime_x) + " and vice versa\n")
        noc_file.write("RX_N_" + str(i + CB_Package.network_dime_x) +
                       "<= TX_S_" + str(i) + ";\n")
        noc_file.write("RX_S_" + str(i) + "<= TX_N_" +
                       str(i + CB_Package.network_dime_x) + ";\n")
        noc_file.write("-------------------\n")
noc_file.write("\n")
noc_file.write("-- horizontal ins/outs\n")

for i in range(CB_Package.network_dime_x * CB_Package.network_dime_y):
    node_x = int(i % CB_Package.network_dime_x)
    node_y = int(i / CB_Package.network_dime_x)
    if node_x != CB_Package.network_dime_x-1:
        noc_file.write("-- connecting router: " + str(i) +
                       " to router: " + str(i + 1) + " and vice versa\n")
        noc_file.write("RX_E_" + str(i) + " <= TX_W_" + str(i + 1) + ";\n")
        noc_file.write("RX_W_" + str(i + 1) + " <= TX_E_" + str(i) + ";\n")
        noc_file.write("-------------------\n")
noc_file.write("-- instantiating the flit trackers\n")

for i in range(CB_Package.network_dime_x * CB_Package.network_dime_y):
    node_x = int(i % CB_Package.network_dime_x)
    node_y = int(i / CB_Package.network_dime_x)
    for input_port in ['N', 'E', 'W', 'S', 'L']:
        noc_file.write("F_T_" + str(i) + "_" + input_port +
                       ": flit_tracker  generic map (\n")
        noc_file.write("        DATA_WIDTH => DATA_WIDTH, \n")
        noc_file.write("        tracker_file =>\"traces/track" +
                       str(i) + "_" + input_port + ".txt\"\n")
        noc_file.write("    )\n")
        noc_file.write("    port map (\n")
        noc_file.write("        clk => clk, RX => RX_" +
                       input_port + "_" + str(i) + ", \n")
        noc_file.write("        valid_in => valid_in_" +
                       input_port + "_" + str(i) + "\n")
        noc_file.write("    );\n")

noc_file.write(
    "---------------------------------------------------------------\n")
noc_file.write("-- binding the routers together\n")

for i in range(CB_Package.network_dime_x * CB_Package.network_dime_y):
    node_x = int(i % CB_Package.network_dime_x)
    node_y = int(i / CB_Package.network_dime_x)

    if node_y != CB_Package.network_dime_y-1:
        noc_file.write("-- connecting router: " + str(i) + " to router: " +
                       str(i + CB_Package.network_dime_x) + " and vice versa\n")

        noc_file.write(
            "valid_in_N_" + str(i + CB_Package.network_dime_x) +
            " <= valid_out_S_" + str(i) + ";\n")

        noc_file.write("valid_in_S_" + str(i) + " <= valid_out_N_" +
                       str(i + CB_Package.network_dime_x) + ";\n")

        noc_file.write("credit_in_S_" + str(i) + " <= credit_out_N_" +
                       str(i + CB_Package.network_dime_x) + ";\n")

        noc_file.write("credit_in_N_" + str(i + CB_Package.network_dime_x) +
                       " <= credit_out_S_" + str(i) + ";\n")

        if CB_Package.vc:
            noc_file.write(
                "valid_in_vc_N_" + str(i + CB_Package.network_dime_x) +
                " <= valid_out_vc_S_" + str(i) + ";\n")

            noc_file.write("valid_in_vc_S_" + str(i) + " <= valid_out_vc_N_" +
                           str(i + CB_Package.network_dime_x) + ";\n")

            noc_file.write("credit_in_vc_S_" + str(i) + " <= credit_out_vc_N_" +
                           str(i + CB_Package.network_dime_x) + ";\n")

            noc_file.write("credit_in_vc_N_" + str(i + CB_Package.network_dime_x) +
                           " <= credit_out_vc_S_" + str(i) + ";\n")

        noc_file.write("-------------------\n")
noc_file.write("\n")

for i in range(CB_Package.network_dime_x * CB_Package.network_dime_y):
    node_x = int(i % CB_Package.network_dime_x)
    node_y = int(i / CB_Package.network_dime_x)

    if node_x != CB_Package.network_dime_x - 1:
        noc_file.write("-- connecting router: " + str(i) +
                       " to router: " + str(i + 1) + " and vice versa\n")

        noc_file.write("valid_in_E_" + str(i) + " <= valid_out_W_" + str(i + 1) + ";\n")
        noc_file.write("valid_in_W_" + str(i + 1) + " <= valid_out_E_" + str(i) + ";\n")
        noc_file.write("credit_in_W_" + str(i + 1) +
                       " <= credit_out_E_" + str(i) + ";\n")

        noc_file.write("credit_in_E_" + str(i) +
                       " <= credit_out_W_" + str(i + 1) + ";\n")

        if CB_Package.vc:
            noc_file.write("valid_in_vc_E_" + str(i) +
                           " <= valid_out_vc_W_" + str(i + 1) + ";\n")
            noc_file.write("valid_in_vc_W_" + str(i + 1) +
                           " <= valid_out_vc_E_" + str(i) + ";\n")
            noc_file.write("credit_in_vc_W_" + str(i + 1) +
                           " <= credit_out_vc_E_" + str(i) + ";\n")
            noc_file.write("credit_in_vc_E_" + str(i) +
                           " <= credit_out_vc_W_" + str(i + 1) + ";\n")

        noc_file.write("-------------------\n")

noc_file.write("end;\n")
