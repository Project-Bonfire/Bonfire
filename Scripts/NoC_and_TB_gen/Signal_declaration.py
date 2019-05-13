# Copyright (C) 2016 Siavoosh Payandeh Azad

def declare_signal_4_dir(signal_name, signal_type, list_of_nodes, dirs):
    """
    generates a set of signals for each direction except Local in the following format:
        signal {signal_name}_{dir}_{nodenum} ... : {signal_type};
    where dir is a direction in set dirs, and nodenum is node number in list_of_nodes.
    """
    string = ""
    for i in list_of_nodes:
        string += "\t signal "
        for j in dirs:
            string += signal_name+"_"+j+"_"+str(i)+", "
        string = string[:-2]+":"+signal_type+";\n"
    string += "\n"
    return string


def declare_signals(noc_file, network_dime_x, network_dime_y, vc):
    """
    noc_file:       string  : path to the network file
    network_dime_x:   integer : No. of nodes along X axis
    network_dime_y:   integer : No. of nodes along Y axis
    """
    noc_file.write("\n\n")
    noc_file.write(
        "-- generating bulk signals. not all of them are used in the design...\n")
    list_of_nodes = range(network_dime_x * network_dime_y)
    dirs =  ["N", "E", "W", "S"]
    noc_file.write(declare_signal_4_dir("credit_out", "std_logic", list_of_nodes, dirs))
    noc_file.write(declare_signal_4_dir("credit_in", "std_logic", list_of_nodes, dirs))
    noc_file.write(declare_signal_4_dir("RX", "std_logic_vector (DATA_WIDTH-1 downto 0)", list_of_nodes, dirs))
    noc_file.write(declare_signal_4_dir("valid_out", "std_logic", list_of_nodes, dirs))
    noc_file.write(declare_signal_4_dir("valid_in", "std_logic", list_of_nodes, dirs))
    noc_file.write(declare_signal_4_dir("TX", "std_logic_vector (DATA_WIDTH-1 downto 0)", list_of_nodes, dirs))

    if vc:
        noc_file.write(declare_signal_4_dir("credit_out_vc", "std_logic", list_of_nodes, dirs))
        noc_file.write(declare_signal_4_dir("credit_in_vc", "std_logic", list_of_nodes, dirs))
        noc_file.write(declare_signal_4_dir("valid_out_vc", "std_logic", list_of_nodes, dirs))
        noc_file.write(declare_signal_4_dir("valid_in_vc", "std_logic", list_of_nodes, dirs))
