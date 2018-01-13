---------------------------------------------------------------------
-- TITLE: Plasma Misc. Package
-- Main AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 2/15/01
-- FILENAME: mlite_pack.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Data types, constants, and add functions needed for the Plasma CPU.

-- modified by: Siavoosh Payandeh Azad
-- Change logs:
--            * An NI has been added to the file as a new module
--            * some changes has been applied to the ports of the older modules
--              to facilitate the new module!
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package router_pack is


  COMPONENT FIFO_credit_based is
      generic (
          DATA_WIDTH: integer := 32
      );
      port (  reset: in  std_logic;
              clk: in  std_logic;
              RX: in std_logic_vector(DATA_WIDTH-1 downto 0);

              valid_in: in std_logic;
              valid_in_vc: in std_logic;

              read_en_N : in std_logic;
              read_en_E : in std_logic;
              read_en_W : in std_logic;
              read_en_S : in std_logic;
              read_en_L : in std_logic;

              read_en_vc_N : in std_logic;
              read_en_vc_E : in std_logic;
              read_en_vc_W : in std_logic;
              read_en_vc_S : in std_logic;
              read_en_vc_L : in std_logic;

              credit_out: out std_logic;
              credit_out_vc: out std_logic;

              empty_out: out std_logic;
              empty_out_vc: out std_logic;

              Data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
              Data_out_vc: out std_logic_vector(DATA_WIDTH-1 downto 0)
      );
  end COMPONENT;


  COMPONENT allocator is

    port (  reset: in  std_logic;
            clk: in  std_logic;
            -- flow control
            credit_in_N, credit_in_E, credit_in_W, credit_in_S, credit_in_L: in std_logic;

            req_N_N, req_N_E, req_N_W, req_N_S, req_N_L: in std_logic;
            req_E_N, req_E_E, req_E_W, req_E_S, req_E_L: in std_logic;
            req_W_N, req_W_E, req_W_W, req_W_S, req_W_L: in std_logic;
            req_S_N, req_S_E, req_S_W, req_S_S, req_S_L: in std_logic;
            req_L_N, req_L_E, req_L_W, req_L_S, req_L_L: in std_logic;
            empty_N, empty_E, empty_W, empty_S, empty_L: in std_logic;
            -- grant_X_Y means the grant for X output port towards Y input port
            -- this means for any X in [N, E, W, S, L] then set grant_X_Y is one hot!
            valid_N, valid_E, valid_W, valid_S, valid_L : out std_logic;

            grant_N_N, grant_N_E, grant_N_W, grant_N_S, grant_N_L: out std_logic;
            grant_E_N, grant_E_E, grant_E_W, grant_E_S, grant_E_L: out std_logic;
            grant_W_N, grant_W_E, grant_W_W, grant_W_S, grant_W_L: out std_logic;
            grant_S_N, grant_S_E, grant_S_W, grant_S_S, grant_S_L: out std_logic;
            grant_L_N, grant_L_E, grant_L_W, grant_L_S, grant_L_L: out std_logic;
            -- vc signals
            credit_in_vc_N, credit_in_vc_E, credit_in_vc_W, credit_in_vc_S, credit_in_vc_L: in std_logic;
            req_N_N_vc, req_N_E_vc, req_N_W_vc, req_N_S_vc, req_N_L_vc: in std_logic;
            req_E_N_vc, req_E_E_vc, req_E_W_vc, req_E_S_vc, req_E_L_vc: in std_logic;
            req_W_N_vc, req_W_E_vc, req_W_W_vc, req_W_S_vc, req_W_L_vc: in std_logic;
            req_S_N_vc, req_S_E_vc, req_S_W_vc, req_S_S_vc, req_S_L_vc: in std_logic;
            req_L_N_vc, req_L_E_vc, req_L_W_vc, req_L_S_vc, req_L_L_vc: in std_logic;
            empty_vc_N, empty_vc_E, empty_vc_W, empty_vc_S, empty_vc_L: in std_logic;
            valid_vc_N, valid_vc_E, valid_vc_W, valid_vc_S, valid_vc_L : out std_logic;
            grant_N_N_vc, grant_N_E_vc, grant_N_W_vc, grant_N_S_vc, grant_N_L_vc: out std_logic;
            grant_E_N_vc, grant_E_E_vc, grant_E_W_vc, grant_E_S_vc, grant_E_L_vc: out std_logic;
            grant_W_N_vc, grant_W_E_vc, grant_W_W_vc, grant_W_S_vc, grant_W_L_vc: out std_logic;
            grant_S_N_vc, grant_S_E_vc, grant_S_W_vc, grant_S_S_vc, grant_S_L_vc: out std_logic;
            grant_L_N_vc, grant_L_E_vc, grant_L_W_vc, grant_L_S_vc, grant_L_L_vc: out std_logic
            );
end COMPONENT;

 COMPONENT LBDR is
  generic (
      cur_addr_rst: integer := 8;
      Rxy_rst: integer := 8;
      Cx_rst: integer := 8
  );
  port (  reset: in  std_logic;
          clk: in  std_logic;
          empty: in  std_logic;
          flit_type: in std_logic_vector(2 downto 0);
          cur_addr_y, cur_addr_x: in std_logic_vector(6 downto 0);
          dst_addr_y, dst_addr_x: in std_logic_vector(6 downto 0);
          grant_N, grant_E, grant_W, grant_S, grant_L: in std_logic;
          Req_N, Req_E, Req_W, Req_S, Req_L:out std_logic
          );
  end COMPONENT;

  COMPONENT XBAR is
    generic (
        DATA_WIDTH: integer := 32
    );
    port (
        North_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        East_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        West_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        South_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        Local_in: in std_logic_vector(DATA_WIDTH-1 downto 0);

        North_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        East_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        West_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        South_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        Local_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);

        sel: in std_logic_vector (9 downto 0);
        Data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end COMPONENT;

  COMPONENT NI_vc is
     generic(current_x : integer := 10; 	-- the current node's x
             current_y : integer := 10; 	-- the current node's y
             NI_depth : integer := 32;
             NI_couter_size: integer:= 5; -- should be set to log2 of NI_depth
             reserved_address : std_logic_vector(29 downto 0)    := "000000000000000001111111111110"; -- NI's memory mapped reserved VC_0
             reserved_address_vc : std_logic_vector(29 downto 0) := "000000000000000001111111111111"; -- NI's memory mapped reserved for VC_1
             flag_address : std_logic_vector(29 downto 0)        := "000000000000000010000000000000";  -- reserved address for the flag register
             counter_address : std_logic_vector(29 downto 0)     := "000000000000000010000000000001");  -- packet counter register address!
     port(clk               : in std_logic;
          reset             : in std_logic;
          enable            : in std_logic;
          write_byte_enable : in std_logic_vector(3 downto 0);
          address           : in std_logic_vector(31 downto 2);
          data_write        : in std_logic_vector(31 downto 0);
          data_read         : out std_logic_vector(31 downto 0);

          -- interrupt signal: disabled!
          irq_out           : out std_logic;

          -- signals for sending packets to network
          credit_in : in std_logic;
          valid_out: out std_logic;
          credit_in_vc: in std_logic;
          valid_out_vc: out std_logic;
          TX: out std_logic_vector(31 downto 0);	-- data sent to the NoC

          -- signals for reciving packets from the network
          credit_out : out std_logic;
          valid_in: in std_logic;
          credit_out_vc: out std_logic;
          valid_in_vc: in std_logic;
          RX: in std_logic_vector(31 downto 0)	-- data recieved form the NoC

  	);
  end COMPONENT; --entity NI_vc

end; --package body
