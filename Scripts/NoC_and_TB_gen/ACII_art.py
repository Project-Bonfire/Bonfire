# Copyright (C) 2016 Siavoosh Payandeh Azad


def generate_ascii_art(noc_file, network_dime_x, network_dime_y):

    noc_file.write("\n\n")
    noc_file.write("--        organizaiton of the network:\n")
    noc_file.write("--     x --------------->\n")
    for j in range(0, network_dime_y):
        if j == 0:
            noc_file.write("--  y  ")
        else:
            noc_file.write("--  |  ")
        for i in range(0, network_dime_x):
            noc_file.write("       ----")
        noc_file.write("\n")
        noc_file.write("--  |       ")
        for i in range(0, network_dime_x):
            if i != network_dime_x-1:
                link = "---"
                 
                if (i+network_dime_x*j) >= 10:
                    noc_file.write(" | "+str(i+network_dime_x*j)+" | "+link)
                else:
                    noc_file.write(" | "+str(i+network_dime_x*j)+"  | "+link)
            else:
                if (i+network_dime_x*j) >= 10:
                    noc_file.write(" | "+str(i+network_dime_x*j)+" |")
                else:
                    noc_file.write(" | "+str(i+network_dime_x*j)+"  |")

        noc_file.write("\n")
        link = "|"
         
        if j == network_dime_y-1:
            noc_file.write("--  v  ")
        else:
            noc_file.write("--  |  ")
        for i in range(0, network_dime_x):
            noc_file.write("       ----")

        if j == network_dime_y-1:
            noc_file.write("\n--   ")
            for i in range(0, network_dime_x):
                noc_file.write("           ")
        else:
            noc_file.write("\n--  |")
            for i in range(0, network_dime_x):
                noc_file.write("          "+link)

        noc_file.write("\n")
