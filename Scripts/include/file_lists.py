
#    The idea here is to make some lists of the necessary files for each scenario
#    in order to make the code a little more organized!


#---------------------------------------------------------
#
#        Credit based related files
#
#---------------------------------------------------------

# Files for the base-line credit based router!
credit_based_files = ["arbiter_in.vhd", "arbiter_out.vhd", "allocator.vhd", "LBDR.vhd",
                      "xbar.vhd", "FIFO_one_hot_credit_based.vhd" ]

credit_based_files_NI = ["arbiter_in.vhd", "arbiter_out.vhd", "allocator.vhd", "LBDR.vhd",
                      "xbar.vhd", "FIFO_one_hot_credit_based.vhd", "NI.vhd"]

vc_files = ["arbiter_in.vhd", "arbiter_out.vhd", "allocator.vhd", "LBDR.vhd",
            "xbar.vhd", "FIFO_one_hot_credit_based.vhd"]

vc_files_NI = ["arbiter_in.vhd", "arbiter_out.vhd", "allocator.vhd", "LBDR.vhd",
            "xbar.vhd", "FIFO_one_hot_credit_based.vhd", "NI.vhd"]
