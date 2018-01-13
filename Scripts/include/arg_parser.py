from helper_func import *
from Help_note import print_help
import sys

def arg_parser(argv, program_argv, logging):
    """
    Arguments parser
        argv:           List of program arguments (sys.argv)
        program_argv:   Dictionary consisting of network configuration variables
        logging:        logging object
    """

    logging.info("starting parsing the progam arguments...")
    logging.debug("program_argv list is following:")
    logging.debug(argv[1:])

    if '--help' in argv[1:] or len(argv) == 1:
        logging.info("printing manual...")
        print_help(argv, program_argv)
        logging.info("exiting the program!")
        sys.exit()

    program_argv['network_dime_x'] = 4
    program_argv['network_dime_y'] = 4
    program_argv['vc'] = False
    program_argv['NI'] = False
    program_argv['NI_depth'] = 0
    program_argv['lat'] = False
    program_argv['debug'] = False
    program_argv['trace'] = False

    if '-D'	in argv[1:]:
        program_argv['network_dime_x'] = int(argv[argv.index('-D')+1])
        program_argv['network_dime_y'] = int(argv[argv.index('-D')+2])
        if program_argv['network_dime_x'] == 1 and program_argv['network_dime_y'] == 1:
            raise ValueError("You cannot build a network with 1 node!")

    if '-lat' in argv[1:]:
        program_argv['lat'] = True

    if '-NI' in argv[1:]:
        program_argv['NI'] = True
        program_argv['NI_depth'] = int(argv[argv.index('-NI')+1])

    if '-vc' in argv[1:]:
        program_argv['vc'] = True

    if '-Rand'	in argv[1:]:
        program_argv['rand'] = float(argv[argv.index('-Rand')+1])
        if program_argv['rand'] < 0 or program_argv['rand'] > 1:
            raise ValueError("Packet injection rate has to be between 0 and 1!")

    if '-BR' in argv[1:]:
        program_argv['BR'] = float(argv[argv.index('-BR')+1])
        if program_argv['BR'] < 0 or program_argv['rand'] > 1:
            raise ValueError("Packet injection rate has to be between 0 and 1!")

    if '-PS' in argv[1:]:
        program_argv['PS'][0] = int(argv[argv.index('-PS')+1])
        program_argv['PS'][1] = int(argv[argv.index('-PS')+2])

    if '-sim' in argv[1:]:
        program_argv['sim'] = int(argv[argv.index('-sim')+1])
        if program_argv['sim'] < 0:
            raise ValueError("Simulation time cannot be negative!")

    if '-end' in argv[1:]:
        program_argv['end'] = int(argv[argv.index('-end')+1])
        if program_argv['end'] < 0:
            raise ValueError("Simulation time cannot be negative!")

    if program_argv['rand'] != -1 and program_argv['BR'] != -1:
        raise ValueError("You cannot specify -Rand and -BR at the same time!")

    if '--debug' in argv[1:]:
        program_argv['debug'] = True

    if '--trace' in argv[1:]:
        program_argv['trace'] = True

    if '-c' in argv[1:]:
        program_argv['command-line'] = True

    logging.info("Finished parsing program arguments")
    logging.info("Command line parameters:")
    for i in program_argv:
        logging.info("\t" + str(i) + ": " + str(program_argv[i]))

    return program_argv

def report_parogram_arguments(program_argv, DEBUG):
    """
    Gets program arguments and Debug and if Debug is True, prints the program
    arguments to the console!
    """
    if DEBUG:
        print_msg(MSG_DEBUG,  "Command line parameters:")
        for i in program_argv:
            print "\t" + i + ": " + str(program_argv[i])
        print
