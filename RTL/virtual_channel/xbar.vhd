--Copyright (C) 2016 Siavoosh Payandeh Azad

library ieee;
use ieee.std_logic_1164.all;

entity XBAR is
    generic (
        DATA_WIDTH: integer := 8
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
end;

architecture behavior of XBAR is
begin
process(sel, North_in, East_in, West_in, South_in, Local_in, North_vc_in, East_vc_in, West_vc_in, South_vc_in, Local_vc_in) begin
    case(sel) is

    	when "0000000001" =>
    		Data_out <= Local_in;
    	when "0000000010" =>
    		Data_out <= South_in;
    	when "0000000100" =>
    		Data_out <= West_in;
    	when "0000001000" =>
    		Data_out <= East_in;
    	when "0000010000" =>
    		Data_out <= North_in;
      when "0000100000" =>
      	Data_out <= Local_vc_in;
      when "0001000000" =>
      	Data_out <= South_vc_in;
      when "0010000000" =>
      	Data_out <= West_vc_in;
      when "0100000000" =>
      	Data_out <= East_vc_in;
      when others =>
      	Data_out <= North_vc_in;
    end case;
   end process;
end;
