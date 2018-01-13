--Copyright (C) 2016 Siavoosh Payandeh Azad


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;
use std.textio.all;
use ieee.std_logic_misc.all;

package TB_Package is
  function CX_GEN(current_address, network_x, network_y : integer) return integer;

   procedure NI_control(network_x, network_y, frame_length, current_address, initial_delay, min_packet_size, max_packet_size: in integer;
                      finish_time: in time;
                      signal clk:                      in std_logic;
                      -- NI configuration
                      signal reserved_address :        in std_logic_vector(29 downto 0);  -- reserved address for sending data to VC 0
                      signal reserved_address_vc :     in std_logic_vector(29 downto 0);  -- reserved address for sending data to VC 1
                      signal flag_address :            in std_logic_vector(29 downto 0) ; -- reserved address for the memory mapped I/O
                      signal counter_address :         in std_logic_vector(29 downto 0);
                      signal reconfiguration_address : in std_logic_vector(29 downto 0);  -- reserved address for reconfiguration register
                      -- NI signals
                      signal enable:                   out std_logic;
                      signal write_byte_enable:        out std_logic_vector(3 downto 0);
                      signal address:                  out std_logic_vector(31 downto 2);
                      signal data_write:               out std_logic_vector(31 downto 0);
                      signal data_read:                in std_logic_vector(31 downto 0);
                      signal test:                out std_logic_vector(31 downto 0));

end TB_Package;

package body TB_Package is
  constant Header_type : std_logic_vector := "001";
  constant Body_type : std_logic_vector := "010";
  constant Tail_type : std_logic_vector := "100";

  function CX_GEN(current_address, network_x, network_y: integer) return integer is
    variable X, Y : integer := 0;
    variable CN, CE, CW, CS : std_logic := '0';
    variable CX : std_logic_vector(3 downto 0);
  begin
    X :=  current_address mod  network_x;
    Y :=  current_address / network_x;

    if X /= 0 then
      CW := '1';
    end if;

    if X /= network_x-1 then
      CE := '1';
    end if;

    if Y /= 0 then
      CN := '1';
    end if;

    if Y /= network_y-1 then
     CS := '1';
    end if;
   CX := CS&CW&CE&CN;
   return to_integer(unsigned(CX));
  end CX_GEN;

  procedure NI_control(network_x, network_y, frame_length, current_address, initial_delay, min_packet_size, max_packet_size: in integer;
                      finish_time: in time;
                      signal clk:                      in std_logic;
                      -- NI configuration
                      signal reserved_address :        in std_logic_vector(29 downto 0);
                      signal reserved_address_vc :     in std_logic_vector(29 downto 0);
                      signal flag_address :            in std_logic_vector(29 downto 0) ; -- reserved address for the memory mapped I/O
                      signal counter_address :         in std_logic_vector(29 downto 0);
                      signal reconfiguration_address : in std_logic_vector(29 downto 0);  -- reserved address for reconfiguration register
                      -- NI signals
                      signal enable:                   out std_logic;
                      signal write_byte_enable:        out std_logic_vector(3 downto 0);
                      signal address:                  out std_logic_vector(31 downto 2);
                      signal data_write:               out std_logic_vector(31 downto 0);
                      signal data_read:                in std_logic_vector(31 downto 0);
                      signal test:                out std_logic_vector(31 downto 0)) is
    -- variables for random functions
    constant DATA_WIDTH : integer := 32;
    variable seed1 :positive := current_address+1;
    variable seed2 :positive := current_address+1;
    variable rand : real ;
    --file handling variables
    variable SEND_LINEVARIABLE : line;
    file SEND_FILE : text;

    variable RECEIVED_LINEVARIABLE : line;
    file RECEIVED_FILE : text;
    -- receiving variables
    variable receive_source_node, receive_destination_node, receive_packet_id, receive_counter, receive_packet_length: integer;
    variable receive_source_node_vc, receive_destination_node_vc, receive_packet_id_vc, receive_counter_vc, receive_packet_length_vc: integer;


    -- sending variables
    variable send_destination_node, send_counter, send_id_counter: integer:= 0;
    variable send_packet_length: integer:= 8;
    type state_type is (Idle, Header_flit, Body_flit, Tail_flit);
    variable  state : state_type;

    variable  frame_starting_delay : integer:= 0;
    variable frame_counter: integer:= 0;
    variable first_packet : boolean := True;

    variable vc: integer := 0; -- virtual channel selector
    variable read_vc: integer := 0; -- virtual channel selector
    begin

    file_open(RECEIVED_FILE,"received.txt",WRITE_MODE);
    file_open(SEND_FILE,"sent.txt",WRITE_MODE);

    enable <= '1';
    state :=  Idle;
    send_packet_length := min_packet_size;
    uniform(seed1, seed2, rand);
    frame_starting_delay := integer(((integer(rand*100.0)*(frame_length - max_packet_size-1)))/100);

    wait until clk'event and clk ='0';
    address <= reconfiguration_address;
    wait until clk'event and clk ='0';
    write_byte_enable <= "1111";

    data_write <= "00000000000000000000" & std_logic_vector(to_unsigned(CX_GEN(current_address, network_x, network_y), 4)) & std_logic_vector(to_unsigned(60, 8));

    wait until clk'event and clk ='0';
    write_byte_enable <= "0000";
    data_write <= (others =>'0');

    while true loop
      -- read the flag status
      address <= flag_address;
      write_byte_enable <= "0000";
      wait until clk'event and clk ='0';


      --flag register is organized like this:
      --       .-------------------------------------------------.
      --       | N2P_empty | P2N_full |                       ...|
      --       '-------------------------------------------------'
      -- Note that VC 1 has higher priority to VC 0
      if  data_read(29) = '0' then  -- N2P VC1 is not empty, can receive flit
          -- set the address for VC1
          address <= reserved_address_vc;
          read_vc := 1;

          write_byte_enable <= "0000";
          wait until clk'event and clk ='0';

          if (data_read(DATA_WIDTH-1 downto DATA_WIDTH-3) = "001") then -- got header flit
              receive_destination_node_vc := to_integer(unsigned(data_read(14 downto 8)))* network_x+to_integer(unsigned(data_read(7 downto 1)));
              receive_source_node_vc :=to_integer(unsigned(data_read(21 downto 15)))* network_x+to_integer(unsigned(data_read(21 downto 15)));
              receive_counter_vc := 1;
          end if;

          if  (data_read(DATA_WIDTH-1 downto DATA_WIDTH-3) = "010") then  -- got body flit
              if receive_counter_vc = 1 then
                  receive_packet_length_vc := to_integer(unsigned(data_read(28 downto 15)));
                  receive_packet_id_vc := to_integer(unsigned(data_read(14 downto 1)));
              end if;
              receive_counter_vc := receive_counter_vc + 1;

          end if;

          if (data_read(DATA_WIDTH-1 downto DATA_WIDTH-3) = "100") then -- got tail flit
              receive_counter_vc := receive_counter_vc +1;
              write(RECEIVED_LINEVARIABLE, "Packet received at " & time'image(now) & " From: " & integer'image(receive_source_node_vc) & " to: " & integer'image(receive_destination_node_vc) & " length: "& integer'image(receive_packet_length_vc) & " actual length: "& integer'image(receive_counter_vc)  & " id: "& integer'image(receive_packet_id_vc)& " VC: "& integer'image(read_vc));
              writeline(RECEIVED_FILE, RECEIVED_LINEVARIABLE);
          end if;

      elsif data_read(31) = '0' then  -- N2P VC0 is not empty, can receive flit
          -- set the address for VC0
          address <= reserved_address;
          read_vc := 0;

          write_byte_enable <= "0000";
          wait until clk'event and clk ='0';

          if (data_read(DATA_WIDTH-1 downto DATA_WIDTH-3) = "001") then -- got header flit
              receive_destination_node := to_integer(unsigned(data_read(14 downto 8)))* network_x+to_integer(unsigned(data_read(7 downto 1)));
              receive_source_node :=to_integer(unsigned(data_read(21 downto 15)))* network_x+to_integer(unsigned(data_read(21 downto 15)));
              receive_counter := 1;
          end if;

          if  (data_read(DATA_WIDTH-1 downto DATA_WIDTH-3) = "010") then  -- got body flit
              if receive_counter = 1 then
                  receive_packet_length := to_integer(unsigned(data_read(28 downto 15)));
                  receive_packet_id := to_integer(unsigned(data_read(14 downto 1)));
              end if;
              receive_counter := receive_counter+1;

          end if;

          if (data_read(DATA_WIDTH-1 downto DATA_WIDTH-3) = "100") then -- got tail flit
              receive_counter := receive_counter+1;
              write(RECEIVED_LINEVARIABLE, "Packet received at " & time'image(now) & " From: " & integer'image(receive_source_node) & " to: " & integer'image(receive_destination_node) & " length: "& integer'image(receive_packet_length) & " actual length: "& integer'image(receive_counter)  & " id: "& integer'image(receive_packet_id)& " VC: "& integer'image(read_vc));
              writeline(RECEIVED_FILE, RECEIVED_LINEVARIABLE);
          end if;


      elsif data_read(30) = '0' then -- P2N is not full, can send flit
          if frame_counter >= frame_starting_delay  then

              if state = Idle and now  < finish_time then
                  if frame_counter < frame_starting_delay+1 then

                    state :=  Header_flit;
                    send_counter := send_counter+1;
                    -- generating the destination address
                    uniform(seed1, seed2, rand);
                    send_destination_node := integer(rand*real((network_x*network_y)-1));
                    while (send_destination_node = current_address) loop
                        uniform(seed1, seed2, rand);
                        send_destination_node := integer(rand*real((network_x*network_y)-1));
                    end loop;

                    uniform(seed1, seed2, rand);
                    vc := integer(rand*real(1));
                    -- this is the header flit
                    if vc = 1 then
                      address <= reserved_address_vc;
                      write_byte_enable <= "1111";
                      -- if you want to write into VC1 you should write "00000000000001" into the sender part! (since the NI sets the source address automatically, the source address field can be used for selecting VC)
                      data_write <= "0000" &  "00000000000001" & std_logic_vector(to_unsigned(send_destination_node/network_x, 7)) & std_logic_vector(to_unsigned(send_destination_node mod network_x, 7));
                    else
                      address <= reserved_address;
                      write_byte_enable <= "1111";
                      data_write <= "0000" &  "00000000000000" & std_logic_vector(to_unsigned(send_destination_node/network_x, 7)) & std_logic_vector(to_unsigned(send_destination_node mod network_x, 7));
                    end if;
                    write(SEND_LINEVARIABLE, "Packet generated at " & time'image(now) & " From " & integer'image(current_address) & " to " & integer'image(send_destination_node) & " with length: "& integer'image(send_packet_length)  & " id: " & integer'image(send_id_counter) & " VC: " & integer'image(vc));
                    writeline(SEND_FILE, SEND_LINEVARIABLE);
                  else
                    state :=  Idle;
                  end if;

              elsif state = Header_flit then

                  --generating the packet length
                  uniform(seed1, seed2, rand);
                  send_packet_length := integer((integer(rand*100.0)*frame_length)/300);
                  if (send_packet_length < min_packet_size) then
                      send_packet_length:=min_packet_size;
                  end if;
                  if (send_packet_length > max_packet_size) then
                      send_packet_length:=max_packet_size;
                  end if;
                  if vc = 1 then
                    address <= reserved_address_vc;
                  else
                    address <= reserved_address;
                  end if;
                  write_byte_enable <= "1111";
                  -- first body flit
                  if first_packet = True then
                    data_write <= "0000" &  std_logic_vector(to_unsigned(send_packet_length, 14)) & std_logic_vector(to_unsigned(send_id_counter, 14));
                  else
                    data_write <= "0000" &  std_logic_vector(to_unsigned(send_packet_length, 14)) & std_logic_vector(to_unsigned(send_id_counter, 14));
                  end if;
                  send_counter := send_counter+1;
                  state :=  Body_flit;
              elsif state = Body_flit then
                  -- rest of body flits
                  if vc = 1 then
                    address <= reserved_address_vc;
                  else
                    address <= reserved_address;
                  end if;
                  write_byte_enable <= "1111";
                  uniform(seed1, seed2, rand);
                  data_write <= "0000" & std_logic_vector(to_unsigned(integer(rand*1000.0), 28));
                  send_counter := send_counter+1;
                  if send_counter = send_packet_length-1 then
                      state :=  Tail_flit;
                  else
                      state :=  Body_flit;
                  end if;
              elsif state = Tail_flit then
                  -- tail flit
                  if vc = 1 then
                    address <= reserved_address_vc;
                  else
                    address <= reserved_address;
                  end if;
                  write_byte_enable <= "1111";
                  if first_packet = True then
                    data_write <= "0000" & "0000000000000000000000000000";
                    first_packet := False;
                  else
                    uniform(seed1, seed2, rand);
                    data_write <= "0000" & std_logic_vector(to_unsigned(integer(rand*1000.0), 28));
                  end if;
                  send_counter := 0;
                  state :=  Idle;
                  -- updating the id counter!
                  send_id_counter := send_id_counter + 1;
                  if send_id_counter = 16384 then
                    send_id_counter := 0;
                  end if;
              end if;
            end if;

            frame_counter := frame_counter + 1;
            if frame_counter = frame_length then
                frame_counter := 0;
                uniform(seed1, seed2, rand);
                frame_starting_delay := integer(((integer(rand*100.0)*(frame_length - max_packet_size)))/100);
            end if;

            wait until clk'event and clk ='0';

      end if;


    end loop;
    file_close(SEND_FILE);
    file_close(RECEIVED_FILE);
  end NI_control;


end TB_Package;
