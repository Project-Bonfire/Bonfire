---------------------------------------------------------------------
-- Copyright (C) 2016 Siavoosh Payandeh Azad
--
-- 	Network interface: Its an interrupt based memory mapped I/O for sending and recieving packets.
--	the data that is sent to NI should be of the following form:
-- 	FIRST write:  4bit source(31-28), 4 bit destination(27-14), 8bit packet length(23-16)
-- 	Body write:  28 bit data(27-0)
-- 	Last write:  28 bit data(27-0)

---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_textio.all;
use std.textio.all;
use ieee.std_logic_misc.all;


entity NI_vc is
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
end; --entity NI_vc

architecture logic of NI_vc is

  -- all the following signals are for sending data from processor to NoC
  signal storage, storage_in : std_logic_vector(31 downto 0);
  signal valid_data_in, valid_data: std_logic;

  -- this old address is put here to make it compatible with Plasma processor!
  signal old_address: std_logic_vector(31 downto 2);

  signal P2N_FIFO_read_pointer, P2N_FIFO_read_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);
  signal P2N_FIFO_write_pointer, P2N_FIFO_write_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);
  signal P2N_write_en: std_logic;

  type MEM is array (0 to NI_depth-1) of std_logic_vector(31 downto 0);
  signal P2N_FIFO, P2N_FIFO_in : MEM;
  signal P2N_full, P2N_empty: std_logic;


  signal credit_counter_in, credit_counter_out: std_logic_vector(1 downto 0);
  signal credit_counter_vc_in, credit_counter_vc_out: std_logic_vector(1 downto 0);
  signal packet_counter_in, packet_counter_out: std_logic_vector(13 downto 0);
  signal packet_length_counter_in, packet_length_counter_out: std_logic_vector(13 downto 0);
  signal grant,grant_vc : std_logic;
  signal vc_select_in, vc_select_out: std_logic;

  type STATE_TYPE IS (IDLE, HEADER_FLIT, BODY_FLIT_1, BODY_FLIT, TAIL_FLIT);
  signal state, state_in   : STATE_TYPE := IDLE;
  signal FIFO_Data_out : std_logic_vector(31 downto 0);
  signal flag_register, flag_register_in : std_logic_vector(31 downto 0);


  -- all the following signals are for sending the packets from NoC to processor
  signal N2P_FIFO, N2P_FIFO_in : MEM;
  signal N2P_FIFO_vc, N2P_FIFO_vc_in : MEM;

  signal N2P_Data_out : std_logic_vector(31 downto 0);

  signal N2P_FIFO_read_pointer, N2P_FIFO_read_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);
  signal N2P_FIFO_write_pointer, N2P_FIFO_write_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);

  signal N2P_FIFO_vc_read_pointer,  N2P_FIFO_vc_read_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);
  signal N2P_FIFO_vc_write_pointer, N2P_FIFO_vc_write_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);

  signal N2P_full, N2P_empty, N2P_full_vc, N2P_empty_vc: std_logic;
  signal N2P_read_en, N2P_read_en_in, N2P_read_en_vc, N2P_read_en_vc_in, N2P_write_en, N2P_write_en_vc: std_logic;
  signal counter_register_in, counter_register : std_logic_vector(1 downto 0);

begin

CLK_proc: process(clk, enable, write_byte_enable) begin
   if reset = '1' then
      storage <= (others => '0');
      valid_data <= '0';
      P2N_FIFO_read_pointer  <= (others=>'0');
      P2N_FIFO_write_pointer <= (others=>'0');

      P2N_FIFO  <= (others => (others=>'0'));

      credit_counter_out <= "11";
      credit_counter_vc_out <= "11";
      packet_length_counter_out <= "00000000000000";
      state <= IDLE;
      packet_counter_out <= "00000000000000";
      ------------------------------------------------
      N2P_FIFO  <= (others => (others=>'0'));
      N2P_FIFO_vc  <= (others => (others=>'0'));

      N2P_FIFO_read_pointer  <= (others=>'0');
      N2P_FIFO_write_pointer <= (others=>'0');

      N2P_FIFO_vc_read_pointer  <= (others=>'0');
      N2P_FIFO_vc_write_pointer <= (others=>'0');

      credit_out <= '0';
      credit_out_vc <= '0';
      counter_register <= (others => '0');
      N2P_read_en <= '0';
      N2P_read_en_vc <= '0';
      flag_register <= (others =>'0');
      old_address <= (others =>'0');
      vc_select_out <= '0';
   elsif clk'event and clk = '1'  then
      old_address <= address;
      P2N_FIFO_write_pointer <= P2N_FIFO_write_pointer_in;
      P2N_FIFO_read_pointer  <=  P2N_FIFO_read_pointer_in;
      credit_counter_out <= credit_counter_in;
      credit_counter_vc_out <= credit_counter_vc_in;
      packet_length_counter_out <= packet_length_counter_in;
      valid_data <= valid_data_in;
      if P2N_write_en = '1' then
        --write into the memory
        P2N_FIFO  <= P2N_FIFO_in;
       end if;
      packet_counter_out <= packet_counter_in;
      if write_byte_enable /= "0000" then
         storage <= storage_in;
      end if;
      state <= state_in;
      ------------------------------------------------
      if N2P_write_en = '1' then
        --write into the memory
        N2P_FIFO <= N2P_FIFO_in;
      end if;

      if N2P_write_en_vc = '1' then
        --write into the memory
        N2P_FIFO_vc <= N2P_FIFO_vc_in;
      end if;
      counter_register <= counter_register_in;
      N2P_FIFO_write_pointer <= N2P_FIFO_write_pointer_in;
      N2P_FIFO_read_pointer  <= N2P_FIFO_read_pointer_in;

      N2P_FIFO_vc_write_pointer <= N2P_FIFO_vc_write_pointer_in;
      N2P_FIFO_vc_read_pointer  <= N2P_FIFO_vc_read_pointer_in;

      credit_out <= '0';
      credit_out_vc <= '0';
      N2P_read_en <= N2P_read_en_in;
      N2P_read_en_vc <= N2P_read_en_vc_in;
      if N2P_read_en = '1' then
        credit_out <= '1';
      end if;
      if N2P_read_en_vc = '1' then
        credit_out_vc <= '1';
      end if;
      flag_register <= flag_register_in;
      vc_select_out <= vc_select_in;
   end if;
end process;

-- everything bellow this line is pure combinatorial!

---------------------------------------------------------------------------------------
--below this is code for communication from PE 2 NoC



P2N_wbe:process(write_byte_enable, enable, address, storage, data_write, valid_data, P2N_write_en) begin
       storage_in <= storage ;
       valid_data_in <= valid_data;

       -- If PE wants to send data to NoC via NI (data is valid)
       if enable = '1' and (address = reserved_address or address = reserved_address_vc) then
          if write_byte_enable /= "0000" then
            valid_data_in <= '1';
          end if;
          if write_byte_enable(0) = '1' then
             storage_in(7 downto 0) <= data_write(7 downto 0);
          end if;
          if write_byte_enable(1) = '1' then
             storage_in(15 downto 8) <= data_write(15 downto 8);
          end if;
          if write_byte_enable(2) = '1' then
             storage_in(23 downto 16) <= data_write(23 downto 16);
          end if;
          if write_byte_enable(3) = '1' then
             storage_in(31 downto 24) <= data_write(31 downto 24);
        end if;
       end if;

       if P2N_write_en = '1' then
          valid_data_in <= '0';
        end if;

    end process;
-----------------------------------------------------------------------------------------------
    -- P2N FIFO handler
    process(storage, P2N_FIFO_write_pointer, P2N_FIFO) begin
        P2N_FIFO_in <= P2N_FIFO;
        P2N_FIFO_in(to_integer(unsigned(P2N_FIFO_write_pointer))) <= storage;
    end process;

    FIFO_Data_out <= P2N_FIFO(to_integer(unsigned(P2N_FIFO_read_pointer)));

-----------------------------------------------------------------------------------------------
-- Write pointer update process (after each write operation, write pointer is rotated one bit to the left)
P2N_wp:  process(P2N_write_en, P2N_FIFO_write_pointer)begin
    if P2N_write_en = '1' then
       P2N_FIFO_write_pointer_in <= P2N_FIFO_write_pointer +1 ;
    else
       P2N_FIFO_write_pointer_in <= P2N_FIFO_write_pointer;
    end if;
  end process;
-----------------------------------------------------------------------------------------------
-- Read pointer update process (after each read operation, read pointer is rotated one bit to the left)
P2N_rp: process(P2N_FIFO_read_pointer, grant, grant_vc)begin
  P2N_FIFO_read_pointer_in <=  P2N_FIFO_read_pointer;
  if grant  = '1' or grant_vc = '1' then
    P2N_FIFO_read_pointer_in <= P2N_FIFO_read_pointer +1;
  end if;
end process;
-----------------------------------------------------------------------------------------------
P2N_write_en_proc:process(P2N_full, valid_data) begin
     if valid_data = '1' and P2N_full ='0' then
         P2N_write_en <= '1';
     else
         P2N_write_en <= '0';
     end if;
  end process;
-----------------------------------------------------------------------------------------------
-- Process for updating full and empty signals
P2N_empy_full:process(P2N_FIFO_write_pointer, P2N_FIFO_read_pointer) begin
      P2N_empty <= '0';
      P2N_full <= '0';
      if P2N_FIFO_read_pointer = P2N_FIFO_write_pointer  then
              P2N_empty <= '1';
      end if;
      if P2N_FIFO_write_pointer = P2N_FIFO_read_pointer - 1 then
              P2N_full <= '1';
      end if;
  end process;

--------------------------------------------------------------------------------
VC_0_credit_counter:process (credit_in, credit_counter_out, grant)begin
    credit_counter_in <= credit_counter_out;
    if credit_in = '1' and grant = '1' then
         credit_counter_in <= credit_counter_out;
    elsif credit_in = '1'  and credit_counter_out < 3 then
         credit_counter_in <= credit_counter_out + 1;
    elsif grant = '1' and credit_counter_out > 0 then
         credit_counter_in <= credit_counter_out - 1;
    end if;
end process;


VC_1_credit_counter:process (credit_in_vc, credit_counter_vc_out, grant_vc)begin
    credit_counter_vc_in <= credit_counter_vc_out;
    if credit_in_vc = '1' and grant_vc = '1' then
         credit_counter_vc_in <= credit_counter_vc_out;
    elsif credit_in_vc = '1'  and credit_counter_vc_out < 3 then
         credit_counter_vc_in <= credit_counter_vc_out + 1;
    elsif grant_vc = '1' and credit_counter_vc_out > 0 then
         credit_counter_vc_in <= credit_counter_vc_out - 1;
    end if;
end process;
--------------------------------------------------------------------------------

Packet_generator: process(P2N_empty, state, credit_counter_out,
                          credit_counter_vc_out,
                          packet_length_counter_out, packet_counter_out,
                          FIFO_Data_out, vc_select_out)
    begin
        -- Some initializations
        vc_select_in <= vc_select_out;
        TX <= (others => '0');
        grant<= '0';
        grant_vc<= '0';
        packet_length_counter_in <= packet_length_counter_out;
        packet_counter_in <= packet_counter_out;

        case(state) is
            when IDLE =>
                if P2N_empty = '0' then
                    state_in <= HEADER_FLIT;
                else
                    state_in <= IDLE;
                end if;

            when HEADER_FLIT =>
                    if FIFO_Data_out(14) = '1' then
                        if credit_counter_vc_out /= "00" and P2N_empty = '0' then
                          grant_vc<= '1';
                          vc_select_in <= '1';
                          TX <= "001" & std_logic_vector(to_unsigned(current_y, 7)) & std_logic_vector(to_unsigned(current_x, 7)) & FIFO_Data_out(13 downto 0) & XOR_REDUCE("001" & std_logic_vector(to_unsigned(current_y, 7)) & std_logic_vector(to_unsigned(current_x, 7)) & FIFO_Data_out(13 downto 0));
                          state_in <= BODY_FLIT_1;
                        else
                              state_in <= HEADER_FLIT;
                        end if;
                    else
                        if credit_counter_out /= "00" and P2N_empty = '0' then
                          grant<= '1';
                          vc_select_in <= '0';
                          TX <= "001" & std_logic_vector(to_unsigned(current_y, 7)) & std_logic_vector(to_unsigned(current_x, 7)) & FIFO_Data_out(13 downto 0) & XOR_REDUCE("001" & std_logic_vector(to_unsigned(current_y, 7)) & std_logic_vector(to_unsigned(current_x, 7)) & FIFO_Data_out(13 downto 0));
                          state_in <= BODY_FLIT_1;
                        else
                              state_in <= HEADER_FLIT;
                        end if;
                    end if;
            when BODY_FLIT_1 =>
                  if vc_select_out = '0' then
                      if credit_counter_out /= "00" and P2N_empty = '0'then
                        packet_length_counter_in <=   (FIFO_Data_out(27 downto 14))-2;
                        grant <= '1';
                        TX <=  "010" &FIFO_Data_out(27 downto 14) &  packet_counter_out & XOR_REDUCE( "010" &FIFO_Data_out(27 downto 14) &  packet_counter_out);
                        state_in <= BODY_FLIT;
                      else
                        state_in <= BODY_FLIT_1;
                      end if;
                  else
                    if credit_counter_vc_out /= "00" and P2N_empty = '0'then
                      packet_length_counter_in <=   (FIFO_Data_out(27 downto 14))-2;
                      grant_vc <= '1';
                      TX <=  "010" &FIFO_Data_out(27 downto 14) &  packet_counter_out & XOR_REDUCE( "010" &FIFO_Data_out(27 downto 14) &  packet_counter_out);
                      state_in <= BODY_FLIT;
                    else
                      state_in <= BODY_FLIT_1;
                    end if;
                  end if;



            when BODY_FLIT =>
              if vc_select_out = '0' then
                if credit_counter_out /= "00" and P2N_empty = '0'then
                    grant <= '1';
                    TX <= "010" & FIFO_Data_out(27 downto 0) & XOR_REDUCE("010" & FIFO_Data_out(27 downto 0));
                    packet_length_counter_in <= packet_length_counter_out - 1;

                    if packet_length_counter_out > 2 then
                      state_in <= BODY_FLIT;
                    else
                      state_in <= TAIL_FLIT;
                    end if;
                else
                    state_in <= BODY_FLIT;
                end if;
              else
                if credit_counter_vc_out /= "00" and P2N_empty = '0'then
                    grant_vc<= '1';
                    TX <= "010" & FIFO_Data_out(27 downto 0) & XOR_REDUCE("010" & FIFO_Data_out(27 downto 0));
                    packet_length_counter_in <= packet_length_counter_out - 1;

                    if packet_length_counter_out > 2 then
                      state_in <= BODY_FLIT;
                    else
                      state_in <= TAIL_FLIT;
                    end if;
                else
                    state_in <= BODY_FLIT;
                end if;
              end if;

            when TAIL_FLIT =>
              if vc_select_out = '0' then
                if credit_counter_out /= "00" and P2N_empty = '0' then
                    grant <= '1';
                    packet_length_counter_in <= packet_length_counter_out - 1;
                    TX <= "100" & FIFO_Data_out(27 downto 0) & XOR_REDUCE("100" & FIFO_Data_out(27 downto 0));
                    packet_counter_in <= packet_counter_out +1;
                    state_in <= IDLE;
                    vc_select_in <= '0';
                else
                    state_in <= TAIL_FLIT;
                end if;
              else
                if credit_counter_vc_out /= "00" and P2N_empty = '0' then
                    grant_vc<= '1';
                    packet_length_counter_in <= packet_length_counter_out - 1;
                    TX <= "100" & FIFO_Data_out(27 downto 0) & XOR_REDUCE("100" & FIFO_Data_out(27 downto 0));
                    packet_counter_in <= packet_counter_out +1;
                    state_in <= IDLE;
                    vc_select_in <= '0';
                else
                    state_in <= TAIL_FLIT;
                end if;
              end if;
            when others =>
                state_in <= IDLE;
            end case ;

end procesS;

valid_out <= grant;
valid_out_vc <= grant_vc;

--------------------------------------------------------------------------------
  vc0_N2P_wr_FIFO_data: process(RX, N2P_FIFO_write_pointer, N2P_FIFO) begin
      N2P_FIFO_in <= N2P_FIFO;
      N2P_FIFO_in(to_integer(unsigned(N2P_FIFO_write_pointer))) <= RX;
  end process;

  vc1_N2P_wr_FIFO_data:process(RX, N2P_FIFO_vc_write_pointer, N2P_FIFO_vc) begin
      N2P_FIFO_vc_in <= N2P_FIFO_vc;
      N2P_FIFO_vc_in(to_integer(unsigned(N2P_FIFO_vc_write_pointer))) <= RX;
  end process;

--------------------------------------------------------------------------------
  N2P_rd_FIFO_data: process(address, N2P_FIFO_read_pointer, N2P_FIFO_vc_read_pointer, N2P_FIFO, N2P_FIFO_vc)
  begin
    if address = reserved_address then
      N2P_Data_out <= N2P_FIFO(to_integer(unsigned(N2P_FIFO_read_pointer)));
    else
      N2P_Data_out <= N2P_FIFO_vc(to_integer(unsigned(N2P_FIFO_vc_read_pointer)));
    end if;
end process;
--------------------------------------------------------------------------------
  N2P_read_enable:process(address, write_byte_enable, N2P_empty, N2P_empty_vc)begin
    if address = reserved_address and write_byte_enable = "0000" and N2P_empty = '0' then
      N2P_read_en_in <= '1';
    else
      N2P_read_en_in <= '0';
    end if;

    if address = reserved_address_vc and write_byte_enable = "0000" and N2P_empty_vc = '0' then
      N2P_read_en_vc_in <= '1';
    else
      N2P_read_en_vc_in <= '0';
    end if;
  end process;

--------------------------------------------------------------------------------
  vc0_N2P_wr_pointer:process(N2P_write_en, N2P_FIFO_write_pointer)begin
    if N2P_write_en = '1'then
       N2P_FIFO_write_pointer_in <= N2P_FIFO_write_pointer + 1;
    else
       N2P_FIFO_write_pointer_in <= N2P_FIFO_write_pointer;
    end if;
  end process;

  vc1_N2P_wr_pointer:process(N2P_write_en_vc, N2P_FIFO_vc_write_pointer)begin
    if N2P_write_en_vc= '1'then
       N2P_FIFO_vc_write_pointer_in <= N2P_FIFO_vc_write_pointer + 1;
    else
       N2P_FIFO_vc_write_pointer_in <= N2P_FIFO_vc_write_pointer;
    end if;
  end process;
--------------------------------------------------------------------------------
  vc0_N2P_rd_pointer:process(N2P_read_en, N2P_empty, N2P_FIFO_read_pointer)begin
       if (N2P_read_en = '1' and N2P_empty = '0') then
           N2P_FIFO_read_pointer_in <= N2P_FIFO_read_pointer + 1;
       else
           N2P_FIFO_read_pointer_in <= N2P_FIFO_read_pointer;
       end if;
  end process;

  vc1_N2P_rd_pointer:process(N2P_read_en_vc, N2P_empty_vc, N2P_FIFO_vc_read_pointer)begin
       if (N2P_read_en_vc = '1' and N2P_empty_vc = '0') then
           N2P_FIFO_vc_read_pointer_in <= N2P_FIFO_vc_read_pointer + 1;
       else
           N2P_FIFO_vc_read_pointer_in <= N2P_FIFO_vc_read_pointer;
       end if;
  end process;
--------------------------------------------------------------------------------
vc0_N2P_wr_en: process(N2P_full, valid_in) begin
     if (valid_in = '1' and N2P_full ='0') then
         N2P_write_en <= '1';
     else
         N2P_write_en <= '0';
     end if;
  end process;

vc1_N2P_wr_en: process(N2P_full_vc, valid_in_vc) begin
     if (valid_in_vc = '1' and N2P_full_vc ='0') then
         N2P_write_en_vc <= '1';
     else
         N2P_write_en_vc <= '0';
     end if;
  end process;
  --------------------------------------------------------------------------------

vc0_N2P_empty_full: process(N2P_FIFO_write_pointer, N2P_FIFO_read_pointer) begin
      if N2P_FIFO_read_pointer = N2P_FIFO_write_pointer  then
              N2P_empty <= '1';
      else
              N2P_empty <= '0';
      end if;

      if N2P_FIFO_write_pointer = N2P_FIFO_read_pointer-1 then
              N2P_full <= '1';
      else
              N2P_full <= '0';
      end if;
  end process;


vc1_N2P_empty_full: process(N2P_FIFO_vc_write_pointer, N2P_FIFO_vc_read_pointer) begin
      if N2P_FIFO_vc_read_pointer = N2P_FIFO_vc_write_pointer  then
              N2P_empty_vc <= '1';
      else
              N2P_empty_vc <= '0';
      end if;

      if N2P_FIFO_vc_write_pointer = N2P_FIFO_vc_read_pointer-1 then
              N2P_full_vc <= '1';
      else
              N2P_full_vc <= '0';
      end if;
  end process;
--------------------------------------------------------------------------------

date_rd: process(N2P_read_en, N2P_Data_out, old_address, flag_register) begin
  if (old_address = reserved_address and N2P_read_en = '1') or
     (old_address = reserved_address_vc and N2P_read_en_vc = '1') then
    data_read <= N2P_Data_out;
      data_read <= N2P_Data_out;
  elsif old_address = flag_address then
    data_read <= flag_register;
  elsif old_address = counter_address then
  	data_read <= "000000000000000000000000000000" & counter_register;
  else
    data_read <= (others => 'U');
  end if;
end process;

-- we have to double check if we need this counter
process(N2P_write_en, N2P_read_en, RX, N2P_Data_out)begin
  counter_register_in <= counter_register;
  if N2P_write_en = '1' and RX(31 downto 29) = "001" and N2P_read_en = '1' and N2P_Data_out(31 downto 29) = "100" then
  	counter_register_in <= counter_register;
  elsif N2P_write_en = '1' and RX(31 downto 29) = "001" then
    counter_register_in <= counter_register +1;
  elsif N2P_read_en = '1' and N2P_Data_out(31 downto 29) = "100" then
  	counter_register_in <= counter_register -1;
  end if;

  if N2P_write_en_vc = '1' and RX(31 downto 29) = "001" and N2P_read_en_vc = '1' and N2P_Data_out(31 downto 29) = "100" then
    counter_register_in <= counter_register;
  elsif N2P_write_en_vc = '1' and RX(31 downto 29) = "001" then
    counter_register_in <= counter_register +1;
  elsif N2P_write_en_vc = '1' and N2P_Data_out(31 downto 29) = "100" then
    counter_register_in <= counter_register -1;
  end if;
end process;

flag_register_in <= N2P_empty & P2N_full & N2P_empty_vc & "00000000000000000000000000000";

irq_out <= '0';
end; --architecture logic
