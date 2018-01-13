# Copyright (C) 2016 Siavoosh Payandeh Azad


def declare_signals(noc_file, network_dime_x, network_dime_y, vc):
    """
    noc_file:       string  : path to the network file
    network_dime_x:   integer : No. of nodes along X axis
    network_dime_y:   integer : No. of nodes along Y axis
    """
    noc_file.write("\n\n")
    noc_file.write("-- generating bulk signals. not all of them are used in the design...\n")

    for i in range(0, network_dime_x*network_dime_y):
        noc_file.write("\tsignal credit_out_N_"+str(i)+", credit_out_E_"+str(i)+", credit_out_W_"+str(i) +
                       ", credit_out_S_"+str(i) + ": std_logic;\n")
    noc_file.write("\n")
    for i in range(0, network_dime_x*network_dime_y):
        noc_file.write("\tsignal credit_in_N_"+str(i)+", credit_in_E_"+str(i)+", credit_in_W_"+str(i) +
                       ", credit_in_S_"+str(i) + ": std_logic;\n")
    noc_file.write("\n")
    for i in range(0, network_dime_x*network_dime_y):
        noc_file.write("\tsignal RX_N_"+str(i)+", RX_E_"+str(i)+", RX_W_"+str(i)+", RX_S_"+str(i) +
                       " : std_logic_vector (DATA_WIDTH-1 downto 0);\n")
    noc_file.write("\n")
    for i in range(0, network_dime_x*network_dime_y):
        noc_file.write("\tsignal valid_out_N_"+str(i)+", valid_out_E_"+str(i)+", valid_out_W_"+str(i) +
                       ", valid_out_S_"+str(i) + ": std_logic;\n")
    noc_file.write("\n")
    for i in range(0, network_dime_x*network_dime_y):
        noc_file.write("\tsignal valid_in_N_"+str(i)+", valid_in_E_"+str(i)+", valid_in_W_"+str(i) +
                       ", valid_in_S_"+str(i) + ": std_logic;\n")
    noc_file.write("\n")
    for i in range(0, network_dime_x*network_dime_y):
        noc_file.write("\tsignal TX_N_"+str(i)+", TX_E_"+str(i)+", TX_W_"+str(i)+", TX_S_"+str(i) +
                       " : std_logic_vector (DATA_WIDTH-1 downto 0);\n")

    if vc:
        for i in range(0, network_dime_x*network_dime_y):
            noc_file.write("\tsignal credit_out_vc_N_"+str(i)+", credit_out_vc_E_"+str(i)+", credit_out_vc_W_"+str(i) +
                           ", credit_out_vc_S_"+str(i) + ": std_logic;\n")
        noc_file.write("\n")
        for i in range(0, network_dime_x*network_dime_y):
            noc_file.write("\tsignal credit_in_vc_N_"+str(i)+", credit_in_vc_E_"+str(i)+", credit_in_vc_W_"+str(i) +
                           ", credit_in_vc_S_"+str(i) + ": std_logic;\n")
        noc_file.write("\n")
        for i in range(0, network_dime_x*network_dime_y):
            noc_file.write("\tsignal valid_out_vc_N_"+str(i)+", valid_out_vc_E_"+str(i)+", valid_out_vc_W_"+str(i) +
                           ", valid_out_vc_S_"+str(i) + ": std_logic;\n")
        noc_file.write("\n")
        for i in range(0, network_dime_x*network_dime_y):
            noc_file.write("\tsignal valid_in_vc_N_"+str(i)+", valid_in_vc_E_"+str(i)+", valid_in_vc_W_"+str(i) +
                           ", valid_in_vc_S_"+str(i) + ": std_logic;\n")
    noc_file.write("\n")
