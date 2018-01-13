# Copyright (C) 2016 Siavoosh Payandeh Azad
import os

# This program runs the simulate script for different Packet Injection Rates
# defined by user in pir_list for dimentions listed in noc_size_list and with
# packet sizes listed in packet_size_list.
# please note that the NI depth "NI_depth" has direct impact on the latency
# results.
# the results will be dumped in two files
#       * latency_result.txt
#       * throughput_result.txt

pir_list = [0.005, 0.01, 0.015, 0.02, 0.025, 0.03]
noc_size_list = [4, 8]
packet_size_list = [4, 8, 16]
# make sure this is equal to your testbench clock period
clock_duration = 10.0 #ns
# this is the depth of the NI FIFO. for better results
# increase it to 128 or higher
NI_depth = 32

latency_result_file = f = open('latency_result.txt', 'w')
throughput_result_file = f = open('throughput_result.txt', 'w')
for network_size in noc_size_list:
    latency_result_file.write("NoC Size: "+str(network_size)+'\n')
    latency_result_file.write(" PS\t\t\t\tPIR\n")
    latency_result_file.write("    "*2+"----------\n")
    latency_result_file.write("   | ")

    throughput_result_file.write("NoC Size: "+str(network_size)+'\n')
    throughput_result_file.write(" PS\t\t\t\tPIR\n")
    throughput_result_file.write("    "*2+"----------\n")
    throughput_result_file.write("   | ")

    for PIR in pir_list:
        latency_result_file.write('%5s' %str(PIR)+"    ")
        throughput_result_file.write('%5s' %str(PIR)+"    ")
    latency_result_file.write("\n")
    throughput_result_file.write("\n")
    for packet_size in  packet_size_list:
        latency_result_file.write('%3s' % str(packet_size)+"| ")
        throughput_result_file.write('%3s' % str(packet_size)+"| ")
        for PIR in pir_list:
            command = 'python ../../simulate.py -D '+str(network_size)+' -NI '+str(NI_depth)+' -Rand '+str(PIR)+' -PS '+str(packet_size)+" "+str(packet_size)+' -sim 50000 -end 62000 -lat'
            os.system(command)
            os.system('cp ../../tmp/simul_temp/latency.txt .')
            f = open('latency.txt', 'r')
            for line in f:
                if 'average' in line:
                    if 'throughput' in line:
                        throughput_result_file.write('%5s' % ("%.1f" % float(float(line.split(":")[1].split(" ")[0])))+"    ")
                    else:
                        latency_result_file.write('%5s' % ("%.1f" % float(float(line.split(":")[1].split(" ")[0])/clock_duration))+"    ")
        latency_result_file.write("\n")
        throughput_result_file.write("\n")
    latency_result_file.write("---------------------\n")
    throughput_result_file.write("---------------------\n")
latency_result_file.close()
throughput_result_file.close()
os.system("rm latency.txt")
