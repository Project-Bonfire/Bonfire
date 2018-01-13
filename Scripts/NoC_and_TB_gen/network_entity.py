# Copyright (C) 2016 Siavoosh Payandeh Azad, Behrad Niazmand


def generate_entity(noc_file, network_dime_x, network_dime_y, vc):
    """
    noc_file:       string  : path to the network file
    network_dime_x:   integer : No. of nodes along X axis
    network_dime_y:   integer : No. of nodes along Y axis
    """
    string_to_print = ""
    noc_file.write("entity network_"+str(network_dime_x)+"x"+str(network_dime_y)+" is\n")

    noc_file.write(" generic (DATA_WIDTH: integer := 32);\n")
    noc_file.write("port (reset: in  std_logic; \n")
    noc_file.write("\tclk: in  std_logic; \n")
    noc_file.write("\t--------------\n")
    for i in range(0, network_dime_x*network_dime_y):
        noc_file.write("\t--------------\n")
        noc_file.write("\tRX_L_"+str(i)+": in std_logic_vector (DATA_WIDTH-1 downto 0);\n")
        noc_file.write("\tcredit_out_L_"+str(i)+", valid_out_L_"+str(i)+": out std_logic;\n")
        noc_file.write("\tcredit_in_L_"+str(i)+", valid_in_L_"+str(i)+": in std_logic;\n")
        if vc:
            noc_file.write("\tcredit_out_vc_L_"+str(i)+", valid_out_vc_L_"+str(i)+": out std_logic;\n")
            noc_file.write("\tcredit_in_vc_L_"+str(i)+", valid_in_vc_L_"+str(i)+": in std_logic;\n")
        if i == network_dime_x*network_dime_y-1:
            noc_file.write("\tTX_L_"+str(i)+": out std_logic_vector (DATA_WIDTH-1 downto 0)\n")
        else:
            noc_file.write("\tTX_L_"+str(i)+": out std_logic_vector (DATA_WIDTH-1 downto 0);\n")

    noc_file.write(string_to_print[:len(string_to_print)-3])
    noc_file.write("\n            ); \n")
    noc_file.write("end network_"+str(network_dime_x)+"x"+str(network_dime_y)+"; \n")
