# Copyright (C) 2016 Siavoosh Payandeh Azad, Behrad Niazmand


def rxy_rst_calculator(node_id):
    # For now we assume XY routing
    rxy_rst = 60
    return rxy_rst


def cx_rst_calculator(node_id, network_dimention_x, network_dimention_y):
    node_x = node_id % network_dimention_x
    node_y = node_id / network_dimention_x
    c_n = 1
    c_e = 1
    c_w = 1
    c_s = 1
    if node_y == 0:
        c_n = 0
    if node_y == network_dimention_y-1:
        c_s = 0
    if node_x == 0:
        c_w = 0
    if node_x == network_dimention_x-1:
        c_e = 0
    return c_s*8+c_w*4+c_e*2+c_n