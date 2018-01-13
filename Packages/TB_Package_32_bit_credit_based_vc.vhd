--Copyright (C) 2016 Siavoosh Payandeh Azad

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
 use ieee.math_real.all;
 use std.textio.all;
 use ieee.std_logic_misc.all;

package TB_Package is
  function Header_gen(network_size_x, source, destination: integer ) return std_logic_vector ;

  function Body_1_gen(Packet_length, packet_id: integer ) return std_logic_vector ;
  function Body_gen(Data: integer ) return std_logic_vector ;

  function Tail_gen(Packet_length, Data: integer ) return std_logic_vector ;

  procedure credit_counter_control(signal clk: in std_logic;
                                 signal credit_in: in std_logic; signal valid_out: in std_logic;
                                 signal credit_counter_out: out std_logic_vector(1 downto 0));
  procedure gen_random_packet(network_size_x, network_size_y, frame_length, source, initial_delay, min_packet_size, max_packet_size: in integer;
                      finish_time: in time; signal clk: in std_logic;
                      signal credit_counter_in: in std_logic_vector(1 downto 0); signal valid_out: out std_logic;
                      signal credit_counter_in_vc: in std_logic_vector(1 downto 0); signal valid_out_vc: out std_logic;
                      signal port_in: out std_logic_vector);
  procedure get_packet(network_size_x, DATA_WIDTH, initial_delay, Node_ID: in integer; signal clk: in std_logic;
                     signal credit_out: out std_logic; signal valid_in: in std_logic;
                     signal credit_out_vc: out std_logic; signal valid_in_vc: in std_logic;
                     signal port_in: in std_logic_vector);
end TB_Package;

package body TB_Package is
  constant Header_type : std_logic_vector := "001";
  constant Body_type : std_logic_vector := "010";
  constant Tail_type : std_logic_vector := "100";

  function Header_gen(network_size_x, source, destination: integer)
              return std_logic_vector is
    	variable Header_flit: std_logic_vector (31 downto 0);
      variable source_x, source_y, destination_x, destination_y: integer;
    	begin

        -- We only need network_size_x for calculation of X and Y coordinates of a node!
      source_x      := source       mod  network_size_x;
      source_y      := source       /    network_size_x;
      destination_x := destination  mod  network_size_x;
      destination_y := destination  /    network_size_x;
      Header_flit := Header_type &  std_logic_vector(to_unsigned(source_y,7)) & std_logic_vector(to_unsigned(source_x,7)) &
                     std_logic_vector(to_unsigned(destination_y,7)) & std_logic_vector(to_unsigned(destination_x,7)) &
                     XOR_REDUCE(Header_type &  std_logic_vector(to_unsigned(source_y,7)) & std_logic_vector(to_unsigned(source_x,7)) &
                     std_logic_vector(to_unsigned(destination_y,7)) & std_logic_vector(to_unsigned(destination_x,7)));

    return Header_flit;
  end Header_gen;

  function Body_1_gen(Packet_length, packet_id: integer)
                return std_logic_vector is
    variable Body_flit: std_logic_vector (31 downto 0);
    begin
    Body_flit := Body_type &  std_logic_vector(to_unsigned(Packet_length, 14))&  std_logic_vector(to_unsigned(packet_id, 14)) &
                 XOR_REDUCE(Body_type &  std_logic_vector(to_unsigned(Packet_length, 14))&  std_logic_vector(to_unsigned(packet_id, 14)));
    return Body_flit;
  end Body_1_gen;


  function Body_gen(Data: integer)
                return std_logic_vector is
    variable Body_flit: std_logic_vector (31 downto 0);
    begin
    Body_flit := Body_type &  std_logic_vector(to_unsigned(Data, 28)) & XOR_REDUCE(Body_type & std_logic_vector(to_unsigned(Data, 28)));
    return Body_flit;
  end Body_gen;


  function Tail_gen(Packet_length, Data: integer)
                return std_logic_vector is
    variable Tail_flit: std_logic_vector (31 downto 0);
    begin
    Tail_flit := Tail_type &  std_logic_vector(to_unsigned(Data, 28)) & XOR_REDUCE(Tail_type & std_logic_vector(to_unsigned(Data, 28)));
    return Tail_flit;
  end Tail_gen;

  procedure credit_counter_control(signal clk: in std_logic;
                                   signal credit_in: in std_logic; signal valid_out: in std_logic;
                                   signal credit_counter_out: out std_logic_vector(1 downto 0)) is

    variable credit_counter: std_logic_vector (1 downto 0);

    begin
    credit_counter := "11";

    while true loop
      credit_counter_out<= credit_counter;
      wait until clk'event and clk ='1';
      if valid_out = '1' and credit_in ='1' then
        credit_counter := credit_counter;
      elsif credit_in = '1' then
        credit_counter := credit_counter + 1;
      elsif valid_out = '1' and  credit_counter > 0 then
        credit_counter := credit_counter - 1;
      else
        credit_counter := credit_counter;
      end if;
    end loop;
  end credit_counter_control;

  procedure gen_random_packet(network_size_x, network_size_y, frame_length, source, initial_delay, min_packet_size, max_packet_size: in integer;
                      finish_time: in time; signal clk: in std_logic;
                      signal credit_counter_in: in std_logic_vector(1 downto 0); signal valid_out: out std_logic;
                      signal credit_counter_in_vc: in std_logic_vector(1 downto 0); signal valid_out_vc: out std_logic;
                      signal port_in: out std_logic_vector) is
    variable seed1 :positive := source+1;
    variable seed2 :positive := source+1;
    variable LINEVARIABLE : line;
    file VEC_FILE : text is out "sent.txt";
    variable rand : real ;
    variable destination_id: integer;
    variable id_counter, frame_starting_delay, Packet_length, frame_ending_delay : integer:= 0;
    variable credit_counter: std_logic_vector (1 downto 0);
    variable vc: integer:= 0;
    begin

    Packet_length := integer((integer(rand*100.0)*frame_length)/100);
    valid_out <= '0';
    valid_out_vc <= '0';
    port_in <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" ;
    wait until clk'event and clk ='1';
    for i in 0 to initial_delay loop
      wait until clk'event and clk ='1';
    end loop;
    port_in <= "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" ;

    while true loop
      -- choose vc
      uniform(seed1, seed2, rand);
      if (integer(rand*2.0) > 1) then
        vc := 1;
      else
        vc := 0;
      end if;

      --generating the frame initial delay
      uniform(seed1, seed2, rand);
      frame_starting_delay := integer(((integer(rand*100.0)*(frame_length - Packet_length-1)))/100);
      --generating the frame ending delay
      frame_ending_delay := frame_length - (Packet_length+frame_starting_delay);

      for k in 0 to frame_starting_delay-1 loop
          wait until clk'event and clk ='0';
      end loop;

      valid_out <= '0';
      valid_out_vc <= '0';

      if vc = 0 then
        while credit_counter_in = 0 loop
          wait until clk'event and clk ='0';
        end loop;
      else
        while credit_counter_in_vc = 0 loop
          wait until clk'event and clk ='0';
        end loop;
      end if;


      -- generating the packet
      id_counter := id_counter + 1;
      if id_counter = 16384 then
          id_counter := 0;
      end if;
      --------------------------------------
      uniform(seed1, seed2, rand);
      Packet_length := integer((integer(rand*100.0)*frame_length)/100);
      if (Packet_length < min_packet_size) then
          Packet_length:=min_packet_size;
      end if;
      if (Packet_length > max_packet_size) then
          Packet_length:=max_packet_size;
      end if;
      --------------------------------------
      uniform(seed1, seed2, rand);
      destination_id := integer(rand*real((network_size_x*network_size_y)-1));
      while (destination_id = source) loop
          uniform(seed1, seed2, rand);
          destination_id := integer(rand*real((network_size_x*network_size_y)-1));
      end loop;
      --------------------------------------
      if vc = 0 then
          write(LINEVARIABLE, "Packet generated at " & time'image(now) & " From " & integer'image(source) & " to " & integer'image(destination_id) & " with length: " & integer'image(Packet_length) & " id: " & integer'image(id_counter) & " vc: 0");
      else
          write(LINEVARIABLE, "Packet generated at " & time'image(now) & " From " & integer'image(source) & " to " & integer'image(destination_id) & " with length: " & integer'image(Packet_length) & " id: " & integer'image(id_counter)& " vc: 1");
      end if;

      writeline(VEC_FILE, LINEVARIABLE);
      wait until clk'event and clk ='0'; -- On negative edge of clk (for syncing purposes)
      port_in <= Header_gen(network_size_x, source, destination_id); -- Generating the header flit of the packet (All packets have a header flit)!

      if vc = 0 then
        valid_out <= '1';
      else
        valid_out_vc <= '1';
      end if;

      wait until clk'event and clk ='0';

      for I in 0 to Packet_length-3 loop
            -- The reason for -3 is that we have packet length of Packet_length, now if you exclude header and tail
            -- it would be Packet_length-2 to enumerate them, you can count from 0 to Packet_length-3.

            if vc = 0 then
                if credit_counter_in = "00" then
                    valid_out <= '0';
                    -- Wait until next router/NI has at least enough space for one flit in its input FIFO
                    wait until credit_counter_in'event and credit_counter_in > 0;
                    wait until clk'event and clk ='0';
                end if;
            else
                if credit_counter_in_vc = "00" then
                    valid_out_vc <= '0';
                    -- Wait until next router/NI has at least enough space for one flit in its input FIFO
                    wait until credit_counter_in_vc'event and credit_counter_in_vc > 0;
                    wait until clk'event and clk ='0';
                end if;
            end if;

            uniform(seed1, seed2, rand);
            -- Each packet can have no body flits or one or more than body flits.
            if I = 0 then
              port_in <= Body_1_gen(Packet_length, id_counter);
            else
              port_in <= Body_gen(integer(rand*1000.0));
            end if;

            if vc = 0 then
              valid_out <= '1';
            else
              valid_out_vc <= '1';
            end if;

            wait until clk'event and clk ='0';
      end loop;

      if vc = 0 then
          if credit_counter_in = "00" then
              valid_out <= '0';
              -- Wait until next router/NI has at least enough space for one flit in its input FIFO
              wait until credit_counter_in'event and credit_counter_in > 0;
              wait until clk'event and clk ='0';
          end if;
      else
          if credit_counter_in_vc = "00" then
              valid_out_vc <= '0';
              -- Wait until next router/NI has at least enough space for one flit in its input FIFO
              wait until credit_counter_in_vc'event and credit_counter_in_vc > 0;
              wait until clk'event and clk ='0';
          end if;
      end if;

      uniform(seed1, seed2, rand);
      -- Close the packet with a tail flit (All packets have one tail flit)!
      port_in <= Tail_gen(Packet_length, integer(rand*1000.0));
      if vc = 0 then
        valid_out <= '1';
      else
        valid_out_vc <= '1';
      end if;
      wait until clk'event and clk ='0';

      if vc = 0 then
        valid_out <= '0';
      else
        valid_out_vc <= '0';
      end if;
      port_in <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" ;

      for l in 0 to frame_ending_delay-1 loop
         wait until clk'event and clk ='0';
      end loop;
      port_in <= "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" ;
      if now > finish_time then
          wait;
      end if;
    end loop;
  end gen_random_packet;



  procedure get_packet(network_size_x, DATA_WIDTH, initial_delay, Node_ID: in integer; signal clk: in std_logic;
                       signal credit_out: out std_logic; signal valid_in: in std_logic;
                       signal credit_out_vc: out std_logic; signal valid_in_vc: in std_logic;
                       signal port_in: in std_logic_vector) is
  -- initial_delay: waits for this number of clock cycles before sending the packet!
    variable source_node_x_vc, source_node_y_vc, destination_node_x_vc, destination_node_y_vc: integer;
    variable source_node_x, source_node_y, destination_node_x, destination_node_y, source_node, destination_node, P_length, packet_id, counter: integer;
    variable source_node_vc, destination_node_vc, P_length_vc, packet_id_vc, counter_vc: integer;
    variable LINEVARIABLE : line;
     file VEC_FILE : text is out "received.txt";

     variable VC : integer;
     variable DIAGNOSIS_vector: std_logic_vector(12 downto 0);
     begin
     credit_out <= '1';
     credit_out_vc <= '1';
     counter := 0;
     counter_vc := 0;
     while true loop

         wait until clk'event and clk ='1';

         if valid_in = '1'  then
              if (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "001") then
                counter := 1;
                source_node_y := to_integer(unsigned(port_in(28 downto 22)));
            source_node_x := to_integer(unsigned(port_in(21 downto 15)));
            destination_node_y := to_integer(unsigned(port_in(14 downto 8)));
            destination_node_x := to_integer(unsigned(port_in(7 downto 1)));

            -- We only needs network_size_x for computing the node ID (convert from (X,Y) coordinate to Node ID)!
            source_node := (source_node_y * network_size_x) + source_node_x;
            destination_node := (destination_node_y * network_size_x) + destination_node_x;


            end if;
            if  (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "010")   then
               if counter = 1 then
                  P_length := to_integer(unsigned(port_in(28 downto 15)));
                  packet_id := to_integer(unsigned(port_in(15 downto 1)));
               end if;
               counter := counter+1;

            end if;
            if (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "100") then
                  counter := counter+1;
                  report "Node: " & integer'image(Node_ID) & "    Packet received at " & time'image(now) & " From " & integer'image(source_node) & " to " & integer'image(destination_node) & " with length: "& integer'image(P_length) & " counter: "& integer'image(counter) & " vc: 0";
                  write(LINEVARIABLE, "Packet received at " & time'image(now) & " From: " & integer'image(source_node) & " to: " & integer'image(destination_node) & " length: "& integer'image(P_length) & " actual length: "& integer'image(counter)  & " id: "& integer'image(packet_id)& " vc: 0");
                  writeline(VEC_FILE, LINEVARIABLE);
                  assert (P_length=counter) report "wrong packet size" severity warning;
                  assert (Node_ID=destination_node) report "wrong packet destination " severity failure;
                  counter := 0;
            end if;


          elsif valid_in_vc = '1'  then
                 if (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "001") then
                   counter_vc := 1;
                   source_node_y_vc := to_integer(unsigned(port_in(28 downto 22)));
                   source_node_x_vc := to_integer(unsigned(port_in(21 downto 15)));
                   destination_node_y_vc := to_integer(unsigned(port_in(14 downto 8)));
                   destination_node_x_vc := to_integer(unsigned(port_in(7 downto 1)));
                   -- We only needs network_size_x for computing the node ID (convert from (X,Y) coordinate to Node ID)!
                   source_node_vc := (source_node_y_vc * network_size_x) + source_node_x_vc;
                   destination_node_vc := (destination_node_y_vc * network_size_x) + destination_node_x_vc;

               end if;
               if  (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "010")   then
                  if counter_vc = 1 then
                     P_length_vc := to_integer(unsigned(port_in(28 downto 15)));
                     packet_id_vc := to_integer(unsigned(port_in(15 downto 1)));
                  end if;
                  counter_vc := counter_vc+1;

               end if;
               if (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "100") then
                   counter_vc := counter_vc+1;
                     report "Node: " & integer'image(Node_ID) & "    Packet received at " & time'image(now) & " From " & integer'image(source_node_vc) & " to " & integer'image(destination_node_vc) & " with length: "& integer'image(P_length_vc) & " counter: "& integer'image(counter_vc) & " vc: 1";
                     write(LINEVARIABLE, "Packet received at " & time'image(now) & " From: " & integer'image(source_node_vc) & " to: " & integer'image(destination_node_vc) & " length: "& integer'image(P_length_vc) & " actual length: "& integer'image(counter_vc)  & " id: "& integer'image(packet_id_vc)& " vc: 1");
                     writeline(VEC_FILE, LINEVARIABLE);
                 assert (P_length=counter_vc) report "wrong packet size" severity warning;
                 assert (Node_ID=destination_node_vc) report "wrong packet destination " severity failure;
                  counter_vc := 0;
               end if;
         end if;

     end loop;
  end get_packet;

end TB_Package;
