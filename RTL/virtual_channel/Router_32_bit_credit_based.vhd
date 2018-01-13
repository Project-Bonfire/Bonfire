--Copyright (C) 2016 Siavoosh Payandeh Azad

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;
use work.router_pack.all;


entity router_credit_based is
	generic (
        DATA_WIDTH: integer := 32;
        current_address : integer := 0;
        Rxy_rst  : integer := 10;
        Cx_rst : integer := 10;
        NoC_size_x: integer := 4
    );
    port (
    reset, clk: in std_logic;

    RX_N, RX_E, RX_W, RX_S, RX_L : in std_logic_vector (DATA_WIDTH-1 downto 0);

    credit_in_N, credit_in_E, credit_in_W, credit_in_S, credit_in_L: in std_logic;
    valid_in_N, valid_in_E, valid_in_W, valid_in_S, valid_in_L : in std_logic;

    valid_out_N, valid_out_E, valid_out_W, valid_out_S, valid_out_L : out std_logic;
    credit_out_N, credit_out_E, credit_out_W, credit_out_S, credit_out_L: out std_logic;

		credit_in_vc_N, credit_in_vc_E, credit_in_vc_W, credit_in_vc_S, credit_in_vc_L: in std_logic;
		valid_in_vc_N, valid_in_vc_E, valid_in_vc_W, valid_in_vc_S, valid_in_vc_L : in std_logic;

		valid_out_vc_N, valid_out_vc_E, valid_out_vc_W, valid_out_vc_S, valid_out_vc_L : out std_logic;
		credit_out_vc_N, credit_out_vc_E, credit_out_vc_W, credit_out_vc_S, credit_out_vc_L: out std_logic;

    TX_N, TX_E, TX_W, TX_S, TX_L: out std_logic_vector (DATA_WIDTH-1 downto 0)
    );
end router_credit_based;


architecture behavior of router_credit_based is

  	signal FIFO_D_out_N, FIFO_D_out_E, FIFO_D_out_W, FIFO_D_out_S, FIFO_D_out_L: std_logic_vector(DATA_WIDTH-1 downto 0);
  	signal FIFO_D_out_vc_N, FIFO_D_out_vc_E, FIFO_D_out_vc_W, FIFO_D_out_vc_S, FIFO_D_out_vc_L: std_logic_vector(DATA_WIDTH-1 downto 0);


 	signal Grant_NN, Grant_NE, Grant_NW, Grant_NS, Grant_NL: std_logic;
 	signal Grant_EN, Grant_EE, Grant_EW, Grant_ES, Grant_EL: std_logic;
 	signal Grant_WN, Grant_WE, Grant_WW, Grant_WS, Grant_WL: std_logic;
 	signal Grant_SN, Grant_SE, Grant_SW, Grant_SS, Grant_SL: std_logic;
 	signal Grant_LN, Grant_LE, Grant_LW, Grant_LS, Grant_LL: std_logic;

	signal Grant_NN_vc, Grant_NE_vc, Grant_NW_vc, Grant_NS_vc, Grant_NL_vc: std_logic;
 	signal Grant_EN_vc, Grant_EE_vc, Grant_EW_vc, Grant_ES_vc, Grant_EL_vc: std_logic;
 	signal Grant_WN_vc, Grant_WE_vc, Grant_WW_vc, Grant_WS_vc, Grant_WL_vc: std_logic;
 	signal Grant_SN_vc, Grant_SE_vc, Grant_SW_vc, Grant_SS_vc, Grant_SL_vc: std_logic;
 	signal Grant_LN_vc, Grant_LE_vc, Grant_LW_vc, Grant_LS_vc, Grant_LL_vc: std_logic;

 	signal Req_NN, Req_EN, Req_WN, Req_SN, Req_LN: std_logic;
 	signal Req_NE, Req_EE, Req_WE, Req_SE, Req_LE: std_logic;
 	signal Req_NW, Req_EW, Req_WW, Req_SW, Req_LW: std_logic;
 	signal Req_NS, Req_ES, Req_WS, Req_SS, Req_LS: std_logic;
 	signal Req_NL, Req_EL, Req_WL, Req_SL, Req_LL: std_logic;

	signal Req_NN_vc, Req_EN_vc, Req_WN_vc, Req_SN_vc, Req_LN_vc: std_logic;
 	signal Req_NE_vc, Req_EE_vc, Req_WE_vc, Req_SE_vc, Req_LE_vc: std_logic;
 	signal Req_NW_vc, Req_EW_vc, Req_WW_vc, Req_SW_vc, Req_LW_vc: std_logic;
 	signal Req_NS_vc, Req_ES_vc, Req_WS_vc, Req_SS_vc, Req_LS_vc: std_logic;
 	signal Req_NL_vc, Req_EL_vc, Req_WL_vc, Req_SL_vc, Req_LL_vc: std_logic;

  signal empty_N, empty_E, empty_W, empty_S, empty_L: std_logic;
	signal empty_vc_N, empty_vc_E, empty_vc_W, empty_vc_S, empty_vc_L: std_logic;

 	signal Xbar_sel_N, Xbar_sel_E, Xbar_sel_W, Xbar_sel_S, Xbar_sel_L: std_logic_vector(9 downto 0);

begin

------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
-- all the FIFOs
FIFO_N: FIFO_credit_based
    generic map ( DATA_WIDTH => DATA_WIDTH)
    port map ( reset => reset, clk => clk, RX => RX_N, valid_in => valid_in_N, valid_in_vc => valid_in_vc_N,
            read_en_N => '0', read_en_E =>Grant_EN, read_en_W =>Grant_WN, read_en_S =>Grant_SN, read_en_L =>Grant_LN,
            read_en_vc_N => '0', read_en_vc_E =>Grant_EN_vc, read_en_vc_W =>Grant_WN_vc, read_en_vc_S =>Grant_SN_vc, read_en_vc_L =>Grant_LN_vc,
            credit_out => credit_out_N, credit_out_vc => credit_out_vc_N,  empty_out => empty_N, empty_out_vc => empty_vc_N, Data_out => FIFO_D_out_N, Data_out_vc => FIFO_D_out_vc_N);

FIFO_E: FIFO_credit_based
    generic map ( DATA_WIDTH => DATA_WIDTH)
    port map ( reset => reset, clk => clk, RX => RX_E, valid_in => valid_in_E, valid_in_vc => valid_in_vc_E,
            read_en_N => Grant_NE, read_en_E =>'0', read_en_W =>Grant_WE, read_en_S =>Grant_SE, read_en_L =>Grant_LE,
						read_en_vc_N => Grant_NE_vc, read_en_vc_E =>'0', read_en_vc_W =>Grant_WE_vc, read_en_vc_S =>Grant_SE_vc, read_en_vc_L =>Grant_LE_vc,
            credit_out => credit_out_E, credit_out_vc => credit_out_vc_E, empty_out => empty_E, empty_out_vc => empty_vc_E, Data_out => FIFO_D_out_E, Data_out_vc => FIFO_D_out_vc_E);

FIFO_W: FIFO_credit_based
    generic map ( DATA_WIDTH => DATA_WIDTH)
    port map ( reset => reset, clk => clk, RX => RX_W, valid_in => valid_in_W, valid_in_vc => valid_in_vc_W,
            read_en_N => Grant_NW, read_en_E =>Grant_EW, read_en_W =>'0', read_en_S =>Grant_SW, read_en_L =>Grant_LW,
						read_en_vc_N => Grant_NW_vc, read_en_vc_E =>Grant_EW_vc, read_en_vc_W =>'0', read_en_vc_S =>Grant_SW_vc, read_en_vc_L =>Grant_LW_vc,
            credit_out => credit_out_W, credit_out_vc => credit_out_vc_W, empty_out => empty_W, empty_out_vc => empty_vc_W, Data_out => FIFO_D_out_W, Data_out_vc => FIFO_D_out_vc_W);

FIFO_S: FIFO_credit_based
    generic map ( DATA_WIDTH => DATA_WIDTH)
    port map ( reset => reset, clk => clk, RX => RX_S, valid_in => valid_in_S, valid_in_vc => valid_in_vc_S,
            read_en_N => Grant_NS, read_en_E =>Grant_ES, read_en_W =>Grant_WS, read_en_S =>'0', read_en_L =>Grant_LS,
						read_en_vc_N => Grant_NS_vc, read_en_vc_E =>Grant_ES_vc, read_en_vc_W =>Grant_WS_vc, read_en_vc_S =>'0', read_en_vc_L =>Grant_LS_vc,
            credit_out => credit_out_S, credit_out_vc => credit_out_vc_S, empty_out => empty_S, empty_out_vc => empty_vc_S, Data_out => FIFO_D_out_S, Data_out_vc => FIFO_D_out_vc_S);

FIFO_L: FIFO_credit_based
    generic map ( DATA_WIDTH => DATA_WIDTH)
    port map ( reset => reset, clk => clk, RX => RX_L, valid_in => valid_in_L, valid_in_vc => valid_in_vc_L,
            read_en_N => Grant_NL, read_en_E =>Grant_EL, read_en_W =>Grant_WL, read_en_S => Grant_SL, read_en_L =>'0',
						read_en_vc_N => Grant_NL_vc, read_en_vc_E =>Grant_EL_vc, read_en_vc_W =>Grant_WL_vc, read_en_vc_S =>Grant_SL_vc, read_en_vc_L =>'0',
            credit_out => credit_out_L, credit_out_vc => credit_out_vc_L, empty_out => empty_L, empty_out_vc => empty_vc_L, Data_out => FIFO_D_out_L, Data_out_vc => FIFO_D_out_vc_L);
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------

-- all the LBDRs
LBDR_N: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
       PORT MAP (reset => reset, clk => clk, empty => empty_N,
             flit_type => FIFO_D_out_N(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
             dst_addr_y => FIFO_D_out_N(14 downto 8),
             dst_addr_x => FIFO_D_out_N(7 downto 1),
             grant_N => '0', grant_E =>Grant_EN, grant_W => Grant_WN, grant_S=>Grant_SN, grant_L =>Grant_LN,
             Req_N=> Req_NN, Req_E=>Req_NE, Req_W=>Req_NW, Req_S=>Req_NS, Req_L=>Req_NL);

LBDR_E: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
   PORT MAP (reset =>  reset, clk => clk, empty => empty_E,
             flit_type => FIFO_D_out_E(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_E(14 downto 8),
						 dst_addr_x => FIFO_D_out_E(7 downto 1),
             grant_N => Grant_NE, grant_E =>'0', grant_W => Grant_WE, grant_S=>Grant_SE, grant_L =>Grant_LE,
             Req_N=> Req_EN, Req_E=>Req_EE, Req_W=>Req_EW, Req_S=>Req_ES, Req_L=>Req_EL);

LBDR_W: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
   PORT MAP (reset =>  reset, clk => clk, empty => empty_W,
             flit_type => FIFO_D_out_W(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_W(14 downto 8),
						 dst_addr_x => FIFO_D_out_W(7 downto 1),
             grant_N => Grant_NW, grant_E =>Grant_EW, grant_W =>'0' ,grant_S=>Grant_SW, grant_L =>Grant_LW,
             Req_N=> Req_WN, Req_E=>Req_WE, Req_W=>Req_WW, Req_S=>Req_WS, Req_L=>Req_WL);

LBDR_S: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
   PORT MAP (reset =>  reset, clk => clk, empty => empty_S,
             flit_type => FIFO_D_out_S(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_S(14 downto 8),
						 dst_addr_x => FIFO_D_out_S(7 downto 1),
             grant_N => Grant_NS, grant_E =>Grant_ES, grant_W =>Grant_WS ,grant_S=>'0', grant_L =>Grant_LS,
             Req_N=> Req_SN, Req_E=>Req_SE, Req_W=>Req_SW, Req_S=>Req_SS, Req_L=>Req_SL);

LBDR_L: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
   PORT MAP (reset =>  reset, clk => clk, empty => empty_L,
             flit_type => FIFO_D_out_L(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_L(14 downto 8),
						 dst_addr_x => FIFO_D_out_L(7 downto 1),
             grant_N => Grant_NL, grant_E =>Grant_EL, grant_W => Grant_WL,grant_S=>Grant_SL, grant_L =>'0',
             Req_N=> Req_LN, Req_E=>Req_LE, Req_W=>Req_LW, Req_S=>Req_LS, Req_L=>Req_LL);

--VC LBDRs
LBDR_vc_N: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
       PORT MAP (reset => reset, clk => clk, empty => empty_vc_N,
             flit_type => FIFO_D_out_vc_N(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_vc_N(14 downto 8),
						 dst_addr_x => FIFO_D_out_vc_N(7 downto 1),
             grant_N => '0', grant_E =>Grant_EN_vc, grant_W => Grant_WN_vc, grant_S=>Grant_SN_vc, grant_L =>Grant_LN_vc,
             Req_N=> Req_NN_vc, Req_E=>Req_NE_vc, Req_W=>Req_NW_vc, Req_S=>Req_NS_vc, Req_L=>Req_NL_vc);

LBDR_vc_E: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
   PORT MAP (reset =>  reset, clk => clk, empty => empty_vc_E,
             flit_type => FIFO_D_out_vc_E(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_vc_E(14 downto 8),
						 dst_addr_x => FIFO_D_out_vc_E(7 downto 1),
             grant_N => Grant_NE_vc, grant_E =>'0', grant_W => Grant_WE_vc, grant_S=>Grant_SE_vc, grant_L =>Grant_LE_vc,
             Req_N=> Req_EN_vc, Req_E=>Req_EE_vc, Req_W=>Req_EW_vc, Req_S=>Req_ES_vc, Req_L=>Req_EL_vc);

LBDR_vc_W: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
   PORT MAP (reset =>  reset, clk => clk, empty => empty_vc_W,
             flit_type => FIFO_D_out_vc_W(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_vc_W(14 downto 8),
						 dst_addr_x => FIFO_D_out_vc_W(7 downto 1),
             grant_N => Grant_NW_vc, grant_E =>Grant_EW_vc, grant_W =>'0' ,grant_S=>Grant_SW_vc, grant_L =>Grant_LW_vc,
             Req_N=> Req_WN_vc, Req_E=>Req_WE_vc, Req_W=>Req_WW_vc, Req_S=>Req_WS_vc, Req_L=>Req_WL_vc);

LBDR_vc_S: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
   PORT MAP (reset =>  reset, clk => clk, empty => empty_vc_S,
             flit_type => FIFO_D_out_vc_S(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_vc_S(14 downto 8),
						 dst_addr_x => FIFO_D_out_vc_S(7 downto 1),
             grant_N => Grant_NS_vc, grant_E =>Grant_ES_vc, grant_W =>Grant_WS_vc ,grant_S=>'0', grant_L =>Grant_LS_vc,
             Req_N=> Req_SN_vc, Req_E=>Req_SE_vc, Req_W=>Req_SW_vc, Req_S=>Req_SS_vc, Req_L=>Req_SL_vc);

LBDR_vc_L: LBDR generic map (Rxy_rst => Rxy_rst, Cx_rst => Cx_rst)
   PORT MAP (reset =>  reset, clk => clk, empty => empty_vc_L,
             flit_type => FIFO_D_out_vc_L(DATA_WIDTH-1 downto DATA_WIDTH-3),
						 cur_addr_y => std_logic_vector(to_unsigned(current_address / NoC_size_x,7)),
						 cur_addr_x => std_logic_vector(to_unsigned(current_address mod NoC_size_x,7)),
						 dst_addr_y => FIFO_D_out_vc_L(14 downto 8),
						 dst_addr_x => FIFO_D_out_vc_L(7 downto 1),
             grant_N => Grant_NL_vc, grant_E =>Grant_EL_vc, grant_W => Grant_WL_vc,grant_S=>Grant_SL_vc, grant_L =>'0',
             Req_N=> Req_LN_vc, Req_E=>Req_LE_vc, Req_W=>Req_LW_vc, Req_S=>Req_LS_vc, Req_L=>Req_LL_vc);
------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------

-- switch allocator

allocator_unit: allocator port map ( reset => reset, clk => clk,
            -- flow control
            credit_in_N => credit_in_N, credit_in_E => credit_in_E, credit_in_W => credit_in_W, credit_in_S => credit_in_S, credit_in_L => credit_in_L,

            -- requests from the LBDRS
            req_N_N => '0',    req_N_E => Req_NE, req_N_W => Req_NW, req_N_S => Req_NS, req_N_L => Req_NL,
            req_E_N => Req_EN, req_E_E => '0',    req_E_W => Req_EW, req_E_S => Req_ES, req_E_L => Req_EL,
            req_W_N => Req_WN, req_W_E => Req_WE, req_W_W => '0',    req_W_S => Req_WS, req_W_L => Req_WL,
            req_S_N => Req_SN, req_S_E => Req_SE, req_S_W => Req_SW, req_S_S => '0',    req_S_L => Req_SL,
            req_L_N => Req_LN, req_L_E => Req_LE, req_L_W => Req_LW, req_L_S => Req_LS, req_L_L => '0',

            empty_N => empty_N, empty_E => empty_E, empty_w => empty_W, empty_S => empty_S, empty_L => empty_L,
            valid_N => valid_out_N, valid_E => valid_out_E, valid_W => valid_out_W, valid_S => valid_out_S, valid_L => valid_out_L,
            -- grant_X_Y means the grant for X output port towards Y input port
            -- this means for any X in [N, E, W, S, L] then set grant_X_Y is one hot!
            grant_N_N => Grant_NN, grant_N_E => Grant_NE, grant_N_W => Grant_NW, grant_N_S => Grant_NS, grant_N_L => Grant_NL,
            grant_E_N => Grant_EN, grant_E_E => Grant_EE, grant_E_W => Grant_EW, grant_E_S => Grant_ES, grant_E_L => Grant_EL,
            grant_W_N => Grant_WN, grant_W_E => Grant_WE, grant_W_W => Grant_WW, grant_W_S => Grant_WS, grant_W_L => Grant_WL,
            grant_S_N => Grant_SN, grant_S_E => Grant_SE, grant_S_W => Grant_SW, grant_S_S => Grant_SS, grant_S_L => Grant_SL,
            grant_L_N => Grant_LN, grant_L_E => Grant_LE, grant_L_W => Grant_LW, grant_L_S => Grant_LS, grant_L_L => Grant_LL,

						-- vc signals
						credit_in_vc_N => credit_in_vc_N, credit_in_vc_E => credit_in_vc_E, credit_in_vc_W => credit_in_vc_W, credit_in_vc_S => credit_in_vc_S, credit_in_vc_L => credit_in_vc_L,

						req_N_N_vc => '0', 		   req_N_E_vc => Req_NE_vc, req_N_W_vc => Req_NW_vc, req_N_S_vc => Req_NS_vc, req_N_L_vc => Req_NL_vc,
            req_E_N_vc => Req_EN_vc, req_E_E_vc => '0', 	    req_E_W_vc => Req_EW_vc, req_E_S_vc => Req_ES_vc, req_E_L_vc => Req_EL_vc,
            req_W_N_vc => Req_WN_vc, req_W_E_vc => Req_WE_vc, req_W_W_vc => '0',       req_W_S_vc => Req_WS_vc, req_W_L_vc => Req_WL_vc,
            req_S_N_vc => Req_SN_vc, req_S_E_vc => Req_SE_vc, req_S_W_vc => Req_SW_vc, req_S_S_vc => '0',       req_S_L_vc => Req_SL_vc,

            req_L_N_vc => Req_LN_vc, req_L_E_vc => Req_LE_vc, req_L_W_vc => Req_LW_vc, req_L_S_vc => Req_LS_vc, req_L_L_vc => '0',
            empty_vc_N => empty_vc_N, empty_vc_E => empty_vc_E, empty_vc_w => empty_vc_W, empty_vc_S => empty_vc_S, empty_vc_L => empty_vc_L,
            valid_vc_N => valid_out_vc_N, valid_vc_E => valid_out_vc_E, valid_vc_W => valid_out_vc_W, valid_vc_S => valid_out_vc_S, valid_vc_L => valid_out_vc_L,
            -- grant_X_Y means the grant for X output port towards Y input port
            -- this means for any X in [N, E, W, S, L] then set grant_X_Y is one hot!
            grant_N_N_vc => Grant_NN_vc, grant_N_E_vc => Grant_NE_vc, grant_N_W_vc => Grant_NW_vc, grant_N_S_vc => Grant_NS_vc, grant_N_L_vc => Grant_NL_vc,
            grant_E_N_vc => Grant_EN_vc, grant_E_E_vc => Grant_EE_vc, grant_E_W_vc => Grant_EW_vc, grant_E_S_vc => Grant_ES_vc, grant_E_L_vc => Grant_EL_vc,
            grant_W_N_vc => Grant_WN_vc, grant_W_E_vc => Grant_WE_vc, grant_W_W_vc => Grant_WW_vc, grant_W_S_vc => Grant_WS_vc, grant_W_L_vc => Grant_WL_vc,
            grant_S_N_vc => Grant_SN_vc, grant_S_E_vc => Grant_SE_vc, grant_S_W_vc => Grant_SW_vc, grant_S_S_vc => Grant_SS_vc, grant_S_L_vc => Grant_SL_vc,
            grant_L_N_vc => Grant_LN_vc, grant_L_E_vc => Grant_LE_vc, grant_L_W_vc => Grant_LW_vc, grant_L_S_vc => Grant_LS_vc, grant_L_L_vc => Grant_LL_vc
            );

------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
-- all the Xbar select_signals

Xbar_sel_N <= '0' 				& Grant_NE_vc & Grant_NW_vc & Grant_NS_vc & Grant_NL_vc  & '0' 			& Grant_NE & Grant_NW & Grant_NS & Grant_NL;
Xbar_sel_E <= Grant_EN_vc & '0' 		 	 	& Grant_EW_vc & Grant_ES_vc & Grant_EL_vc  & Grant_EN & '0' 		 & Grant_EW & Grant_ES & Grant_EL;
Xbar_sel_W <= Grant_WN_vc & Grant_WE_vc & '0' 				& Grant_WS_vc & Grant_WL_vc  & Grant_WN & Grant_WE & '0' 			& Grant_WS & Grant_WL;
Xbar_sel_S <= Grant_SN_vc & Grant_SE_vc & Grant_SW_vc & '0' 		    & Grant_SL_vc  & Grant_SN & Grant_SE & Grant_SW & '0' 		 & Grant_SL;
Xbar_sel_L <= Grant_LN_vc & Grant_LE_vc & Grant_LW_vc & Grant_LS_vc & '0' 				 & Grant_LN & Grant_LE & Grant_LW & Grant_LS & '0';


------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------
 -- all the Xbars
XBAR_N: XBAR generic map (DATA_WIDTH  => DATA_WIDTH)
   PORT MAP (North_in => FIFO_D_out_N, East_in => FIFO_D_out_E, West_in => FIFO_D_out_W, South_in => FIFO_D_out_S, Local_in => FIFO_D_out_L,
	 					 North_vc_in => FIFO_D_out_vc_N, East_vc_in => FIFO_D_out_vc_E, West_vc_in => FIFO_D_out_vc_W, South_vc_in => FIFO_D_out_vc_S, Local_vc_in => FIFO_D_out_vc_L,
        		 sel => Xbar_sel_N,  Data_out=> TX_N);
XBAR_E: XBAR generic map (DATA_WIDTH  => DATA_WIDTH)
   PORT MAP (North_in => FIFO_D_out_N, East_in => FIFO_D_out_E, West_in => FIFO_D_out_W, South_in => FIFO_D_out_S, Local_in => FIFO_D_out_L,
	 					 North_vc_in => FIFO_D_out_vc_N, East_vc_in => FIFO_D_out_vc_E, West_vc_in => FIFO_D_out_vc_W, South_vc_in => FIFO_D_out_vc_S, Local_vc_in => FIFO_D_out_vc_L,
             sel => Xbar_sel_E,  Data_out=> TX_E);
XBAR_W: XBAR generic map (DATA_WIDTH  => DATA_WIDTH)
   PORT MAP (North_in => FIFO_D_out_N, East_in => FIFO_D_out_E, West_in => FIFO_D_out_W, South_in => FIFO_D_out_S, Local_in => FIFO_D_out_L,
	 					 North_vc_in => FIFO_D_out_vc_N, East_vc_in => FIFO_D_out_vc_E, West_vc_in => FIFO_D_out_vc_W, South_vc_in => FIFO_D_out_vc_S, Local_vc_in => FIFO_D_out_vc_L,
        		 sel => Xbar_sel_W,  Data_out=> TX_W);
XBAR_S: XBAR generic map (DATA_WIDTH  => DATA_WIDTH)
   PORT MAP (North_in => FIFO_D_out_N, East_in => FIFO_D_out_E, West_in => FIFO_D_out_W, South_in => FIFO_D_out_S, Local_in => FIFO_D_out_L,
	 					 North_vc_in => FIFO_D_out_vc_N, East_vc_in => FIFO_D_out_vc_E, West_vc_in => FIFO_D_out_vc_W, South_vc_in => FIFO_D_out_vc_S, Local_vc_in => FIFO_D_out_vc_L,
        		 sel => Xbar_sel_S,  Data_out=> TX_S);
XBAR_L: XBAR generic map (DATA_WIDTH  => DATA_WIDTH)
   PORT MAP (North_in => FIFO_D_out_N, East_in => FIFO_D_out_E, West_in => FIFO_D_out_W, South_in => FIFO_D_out_S, Local_in => FIFO_D_out_L,
	 					 North_vc_in => FIFO_D_out_vc_N, East_vc_in => FIFO_D_out_vc_E, West_vc_in => FIFO_D_out_vc_W, South_vc_in => FIFO_D_out_vc_S, Local_vc_in => FIFO_D_out_vc_L,
        		 sel => Xbar_sel_L,  Data_out=> TX_L);

end;
