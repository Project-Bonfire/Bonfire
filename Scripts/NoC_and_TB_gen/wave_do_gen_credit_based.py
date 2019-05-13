import sys

def add2wave_sig_iter(signal_names, radix, colors, group, options, node_list):
    # iterates over signals in a single module, basically adds node number at the end of each signal in signal_names
    string = ""
    for i in node_list:
        for signal in signal_names:
            string += "add wave "+options+" -group {"+group+"} -color "+colors[signal_names.index(signal)]+" -radix "+radix+" :" +\
        			   signal+"_" + str(i) + "\n"
    return string

def add2wave_Module(module_name, signal_names, radix, color, group, options, node_list):
    # iterates over all nodes, finds all the signals in the module_name+node_num+signal_name
    string = ""
    for i in node_list:
        for signal in signal_names:
            string += "add wave "+options+" -group {"+group+"} -color "+color+" -radix "+radix+" :" +\
                      module_name+"_" + str(i) +":"+signal+"\n"
    return string

if '-D' in sys.argv[1:]:
    network_dime_x = int(sys.argv[sys.argv.index('-D') + 1])
    network_dime_y = int(sys.argv[sys.argv.index('-D') + 2])
else:
    # Default nework size is 4x4!
    network_dime_x = 4
    network_dime_4 = 4

if '-o' in sys.argv[1:]:
    file_path = sys.argv[sys.argv.index('-o') + 1]
    if ".do" not in file_path:
        raise ValueError("wrong file extention. only do files are accepted!")
else:
    file_path = 'wave_' + str(network_dime_x) + "x" + str(network_dime_y) + '.do'

wave_file = open(file_path, 'w')

tb_name = "tb_network_" + str(network_dime_x) + "x" + str(network_dime_y)


wave_file.write("onerror {resume}\n")
wave_file.write("quietly WaveActivateNextPane {} 0\n")
node_list = range(network_dime_x*network_dime_y)
wave_file.write(add2wave_sig_iter([tb_name + ":RX_L"], "decimal", ["green"], "NoC RX", "-noupdate", node_list))
wave_file.write(add2wave_sig_iter([tb_name + ":TX_L"], "decimal", ["green"], "NoC TX", "-noupdate", node_list))

for i in range(network_dime_x * network_dime_y):
    if i / network_dime_x != 0:  # Y coordinate
        wave_file.write("add wave -noupdate -group {Link NoC RX} -color green -radix decimal :" + tb_name + ":NoC:R_" + str(i) + ":RX_N\n")
    if i % network_dime_x != network_dime_x - 1:  # X coordinate
        wave_file.write("add wave -noupdate -group {Link NoC RX} -color green -radix decimal :" + tb_name + ":NoC:R_" + str(i) + ":RX_E\n")
    if i % network_dime_x != 0:  # X coordinate
        wave_file.write("add wave -noupdate -group {Link NoC RX} -color green -radix decimal :" + tb_name + ":NoC:R_" + str(i) + ":RX_W\n")
    if i / network_dime_x != network_dime_y - 1:  # Y coordinate
        wave_file.write("add wave -noupdate -group {Link NoC RX} -color green -radix decimal :" + tb_name + ":NoC:R_" + str(i) + ":RX_S\n")

for i in range(network_dime_x * network_dime_y):
    if i / network_dime_x != 0:  # Y coordinate
        wave_file.write("add wave -noupdate -group {Link NoC TX} -color green -radix decimal :" + tb_name + ":NoC:R_" + str(i) + ":TX_N\n")
    if i % network_dime_x != network_dime_x - 1:  # X coordinate
        wave_file.write("add wave -noupdate -group {Link NoC TX} -color green -radix decimal :" + tb_name + ":NoC:R_" + str(i) + ":TX_E\n")
    if i % network_dime_x != 0:  # X coordinate
        wave_file.write("add wave -noupdate -group {Link NoC TX} -color green -radix decimal :" + tb_name + ":NoC:R_" + str(i) + ":TX_W\n")
    if i / network_dime_x != network_dime_y - 1:  # Y coordinate
        wave_file.write("add wave -noupdate -group {Link NoC TX} -color green -radix decimal :" + tb_name + ":NoC:R_" + str(i) + ":TX_S\n")

signal_names = [tb_name+":RX_L", tb_name + ":valid_in_L", tb_name + ":credit_out_L",
                tb_name + ":TX_L", tb_name + ":valid_out_L", tb_name + ":credit_in_L"]
colors = ["Gold"]*3+ ["Violet"]*3
wave_file.write(add2wave_sig_iter(signal_names, "decimal", colors, "NoC Detailed", "-noupdate", node_list))

signal_names = ["FIFO_N:empty", "FIFO_E:empty", "FIFO_W:empty", "FIFO_S:empty", "FIFO_L:empty"]
colors = ["green"]*len(signal_names)
wave_file.write(add2wave_Module(tb_name + ":NoC:R", signal_names, "decimal", "green", "NoC Empty_Sigs", "-noupdate", node_list))
wave_file.write(		"add wave -noupdate -group {NoC Empty_Sigs} :" + tb_name + ":clk\n")

signal_names = ["FIFO_N:full", "FIFO_E:full", "FIFO_W:full", "FIFO_S:full", "FIFO_L:full"]
colors = ["green"]*len(signal_names)
wave_file.write(add2wave_Module(tb_name + ":NoC:R", signal_names, "decimal", "green", "NoC Full_Sigs", "-noupdate", node_list))
wave_file.write(		"add wave -noupdate -group {NoC Empty_Sigs} :" + tb_name + ":clk\n")



wave_file.write("TreeUpdate [SetDefaultTree]\n")
wave_file.write("WaveRestoreCursors\n")
wave_file.write("quietly wave cursor active 0\n")
wave_file.write("configure wave -namecolwidth 396\n")
wave_file.write("configure wave -valuecolwidth 100\n")
wave_file.write("configure wave -justifyvalue left\n")
wave_file.write("configure wave -signalnamewidth 0\n")
wave_file.write("configure wave -snapdistance 10\n")
wave_file.write("configure wave -datasetprefix 0\n")
wave_file.write("configure wave -rowmargin 4\n")
wave_file.write("configure wave -childrowmargin 2\n")
wave_file.write("configure wave -gridoffset 0\n")
wave_file.write("configure wave -gridperiod 1\n")
wave_file.write("configure wave -griddelta 40\n")
wave_file.write("configure wave -timeline 0\n")
wave_file.write("configure wave -timelineunits ns\n")
wave_file.write("update\n")
wave_file.write("WaveRestoreZoom {0 ps} {147 ns}\n")
wave_file.close()
