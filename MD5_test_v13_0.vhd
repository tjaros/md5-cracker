library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity pw_gen is
    Port ( 
clk : in STD_LOGIC;    
reset : in STD_LOGIC; 
bl : in UNSIGNED(7 downto 0);
pw_guess : out STD_LOGIC_VECTOR(79 downto 0)

);
end pw_gen;


architecture RTL of pw_gen is

signal pw_del : std_logic_vector(79 downto 0) := (others => '0');
signal count_i, count_j, count_k, count_l, count_m, count_n, count_o, count_p : unsigned(7 downto 0):= "00100000"; --20

--state
type state_type is (s1, s2, s3, s4, s5, s6, s7, s8);
signal state : state_type;

begin

----------------------- guess pw generation pw_guess ------------------------------------------------
--FSM1 : 20 - 2f
pw_gen1 : process(clk, reset, bl)
    begin    
        if(reset = '1') then
            pw_guess <= (others => '0');
            state <= s1; 
            count_i <= bl;
            count_j <= bl;
            count_k <= bl;
            count_l <= bl;
            count_m <= bl;
            count_n <= bl;
            count_o <= bl;
            count_p <= bl;
        
        elsif rising_edge(clk) then
        
            case state is  
                                
                when s1 =>  --checks for 1st position between 20h to 37h                      
                    pw_guess(55 downto 48) <= std_logic_vector(count_i);  
                    pw_guess(63) <= '1';
                    pw_guess(7 downto 0) <= x"08"; 
                    if (count_i = bl+1) then
                        count_i <= x"41"; 
                        state <= s2;
                    else
                        count_i <= count_i + 1;  
                    end if;   
                    
                when s2 =>  --check first 2 positions
                    pw_guess(63 downto 48) <= std_logic_vector(count_i) & std_logic_vector(count_j);  --always count_i is faster
                    pw_guess(71) <= '1';
                    pw_guess(7 downto 0) <= x"10"; 
                    if (count_i = x"7a") then                             
                        if (count_j = bl+1) then
                            count_i <= x"41";
                            count_j <= x"41";
                            state <= s3;
                        else
                            count_j <= count_j + 1;
                            count_i <= x"41";                            
                        end if;
                    else
                        count_i <= count_i + 1;
                    end if;  

                    
                when s3 =>  --check first 3 positions
                    pw_guess(71 downto 48) <= std_logic_vector(count_i)& std_logic_vector(count_j)& std_logic_vector(count_k);  
                    pw_guess(79) <= '1';
                    pw_guess(7 downto 0) <= x"18";
                    if (count_i = x"7a") then                            
                        if (count_j = x"7a") then 
                            if (count_k = bl+1) then
                                count_i <= x"41"; 
                                count_j <= x"41"; 
                                count_k <= x"41"; 
                                state <= s4;
                            else
                                count_k <= count_k + 1;
                                count_i <= x"41";
                                count_j <= x"41";
                            end if;
                         else
                            count_j <= count_j +1;
                            count_i <= x"41";
                        end if;
                    else
                        count_i <= count_i + 1;    
                    end if;
                    
                    
                when s4 =>  --check first 4 positions
                    pw_guess(79 downto 48) <= std_logic_vector(count_i)& std_logic_vector(count_j)& std_logic_vector(count_k) & std_logic_vector(count_l);  
                    pw_guess(23) <= '1';
                    pw_guess(7 downto 0) <= x"20";
                    if (count_i = x"7a") then                            
                        if (count_j = x"7a") then 
                            if (count_k = x"7a") then
                                if (count_l = bl+1) then
                                    count_i <= x"41"; 
                                    count_j <= x"41"; 
                                    count_k <= x"41"; 
                                    count_l <= x"41";
                                    state <= s5;
                                else
                                    count_l <= count_l + 1; 
                                    count_i <= x"41";
                                    count_j <= x"41";
                                    count_k <= x"41";
                                end if;
                            else
                                count_k <= count_k + 1;
                                count_i <= x"41";
                                count_j <= x"41";
                            end if;
                         else
                            count_j <= count_j +1;
                            count_i <= x"41";
                        end if;
                    else
                        count_i <= count_i + 1;    
                    end if;
                    
                when s5 =>  --check first 5 positions
                    pw_guess(23 downto 16)<= std_logic_vector(count_i);
                    pw_guess(79 downto 48) <= std_logic_vector(count_j)& std_logic_vector(count_k)& std_logic_vector(count_l)& std_logic_vector(count_m);  
                    pw_guess(31) <= '1';
                    pw_guess(7 downto 0) <= x"28";
                    if (count_i = x"7a") then                            
                        if (count_j = x"7a") then 
                            if (count_k = x"7a") then
                                if (count_l = x"7a") then
                                    if (count_m = bl+1) then                                    
                                        count_i <= x"41"; 
                                        count_j <= x"41"; 
                                        count_k <= x"41"; 
                                        count_l <= x"41";
                                        count_m <= x"41";
                                        state <= s6;
                                    else  
                                        count_m <= count_m + 1;                                  
                                        count_i <= x"41"; 
                                        count_j <= x"41"; 
                                        count_k <= x"41"; 
                                        count_l <= x"41";
                                    end if;
                                else
                                    count_l <= count_l + 1;
                                    count_i <= x"41";
                                    count_j <= x"41";
                                    count_k <= x"41";
                                end if;
                            else
                                count_k <= count_k + 1;
                                count_i <= x"41";
                                count_j <= x"41";
                            end if;
                         else
                            count_j <= count_j +1;
                            count_i <= x"41";
                        end if;
                    else
                        count_i <= count_i + 1;    
                    end if; 
                    
            
                    when s6 =>  --check first 6 positions
                    pw_guess(31 downto 16)<= std_logic_vector(count_i) & std_logic_vector(count_j);
                    pw_guess(79 downto 48) <= std_logic_vector(count_k)& std_logic_vector(count_l)& std_logic_vector(count_m)& std_logic_vector(count_n);  
                    pw_guess(39) <= '1';
                    pw_guess(7 downto 0) <= x"30";
                    if (count_i = x"7a") then                            
                        if (count_j = x"7a") then 
                            if (count_k = x"7a") then
                                if (count_l = x"7a") then
                                    if (count_m = x"7a") then 
                                        if (count_n = bl+1) then                                    
                                            count_i <= x"41"; 
                                            count_j <= x"41"; 
                                            count_k <= x"41"; 
                                            count_l <= x"41";
                                            count_m <= x"41";
                                            count_n <= x"41";
                                            state <= s7;
                                        else
                                            count_n <= count_n + 1;                                  
                                            count_i <= x"41"; 
                                            count_j <= x"41"; 
                                            count_k <= x"41"; 
                                            count_l <= x"41";
                                            count_m <= x"41";
                                        end if;
                                    else  
                                        count_m <= count_m + 1;                                  
                                        count_i <= x"41"; 
                                        count_j <= x"41"; 
                                        count_k <= x"41"; 
                                        count_l <= x"41";
                                    end if;
                                else
                                    count_l <= count_l + 1;
                                    count_i <= x"41";
                                    count_j <= x"41";
                                    count_k <= x"41";
                                end if;
                            else
                                count_k <= count_k + 1;
                                count_i <= x"41";
                                count_j <= x"41";
                            end if;
                         else
                            count_j <= count_j +1;
                            count_i <= x"41";
                        end if;
                    else
                        count_i <= count_i + 1;    
                    end if;    
                    
                    when s7 =>  --check first 7 positions
                    pw_guess(39 downto 16) <= std_logic_vector(count_i) & std_logic_vector(count_j) & std_logic_vector(count_k);
                    pw_guess(79 downto 48) <= std_logic_vector(count_l) & std_logic_vector(count_m) & std_logic_vector(count_n) & std_logic_vector(count_o);  
                    pw_guess(47) <= '1';
                    pw_guess(7 downto 0) <= x"38";
                    if (count_i = x"7a") then                            
                        if (count_j = x"7a") then 
                            if (count_k = x"7a") then
                                if (count_l = x"7a") then
                                    if (count_m = x"7a") then 
                                        if (count_n = x"7a") then
                                            if (count_o = bl+1) then                                     
                                                --search done till 7-char pw; more than that it's impractical
                                                state <= s8;
                                            else
                                                count_o <= count_o + 1;
                                                count_i <= x"41"; 
                                                count_j <= x"41"; 
                                                count_k <= x"41"; 
                                                count_l <= x"41";
                                                count_m <= x"41";
                                                count_n <= x"41";
                                        end if;
                                                 
                                        else
                                            count_n <= count_n + 1;                                  
                                            count_i <= x"41"; 
                                            count_j <= x"41"; 
                                            count_k <= x"41"; 
                                            count_l <= x"41";
                                            count_m <= x"41";
                                        end if;
                                    else  
                                        count_m <= count_m + 1;                                  
                                        count_i <= x"41"; 
                                        count_j <= x"41"; 
                                        count_k <= x"41"; 
                                        count_l <= x"41";
                                    end if;
                                else
                                    count_l <= count_l + 1;
                                    count_i <= x"41";
                                    count_j <= x"41";
                                    count_k <= x"41";
                                end if;
                            else
                                count_k <= count_k + 1;
                                count_i <= x"41";
                                count_j <= x"41";
                            end if;
                         else
                            count_j <= count_j +1;
                            count_i <= x"41";
                        end if;
                    else
                        count_i <= count_i + 1;    
                    end if;                     
                      
                  when s8 =>  --check first 8 positions
                  pw_guess(47 downto 16) <= std_logic_vector(count_i) & std_logic_vector(count_j) & std_logic_vector(count_k) & std_logic_vector(count_l);
                  pw_guess(79 downto 48) <=  std_logic_vector(count_m) & std_logic_vector(count_n) & std_logic_vector(count_o) & std_logic_vector(count_p);  
                  pw_guess(15) <= '1';
                  pw_guess(7 downto 0) <= x"40";
                  if (count_i = x"7a") then                            
                      if (count_j = x"7a") then 
                          if (count_k = x"7a") then
                              if (count_l = x"7a") then
                                  if (count_m = x"7a") then 
                                      if (count_n = x"7a") then
                                          if (count_o = x"7a") then
                                              if (count_p = bl+1) then                                     
                                                  --search done till 8-char pw; more than that it's impractical
                                                  state <= s1;
                                              else
                                                  count_p <= count_p + 1;                                                    
                                                  count_i <= x"41"; 
                                                  count_j <= x"41"; 
                                                  count_k <= x"41"; 
                                                  count_l <= x"41";
                                                  count_m <= x"41";
                                                  count_n <= x"41";
                                                  count_o <= x"41";
                                              end if;
                               
                                      else
                                          count_o <= count_o + 1;
                                          count_i <= x"41"; 
                                          count_j <= x"41"; 
                                          count_k <= x"41"; 
                                          count_l <= x"41";
                                          count_m <= x"41";
                                          count_n <= x"41";
                                  end if;
                                               
                                      else
                                          count_n <= count_n + 1;                                  
                                          count_i <= x"41"; 
                                          count_j <= x"41"; 
                                          count_k <= x"41"; 
                                          count_l <= x"41";
                                          count_m <= x"41";
                                      end if;
                                  else  
                                      count_m <= count_m + 1;                                  
                                      count_i <= x"41"; 
                                      count_j <= x"41"; 
                                      count_k <= x"41"; 
                                      count_l <= x"41";
                                  end if;
                              else
                                  count_l <= count_l + 1;
                                  count_i <= x"41";
                                  count_j <= x"41";
                                  count_k <= x"41";
                              end if;
                          else
                              count_k <= count_k + 1;
                              count_i <= x"41";
                              count_j <= x"41";
                          end if;
                       else
                          count_j <= count_j +1;
                          count_i <= x"41";
                      end if;
                  else
                      count_i <= count_i + 1;    
                  end if; 
                                  
                end case;
        end if;
end process;

end rtl; 
    
------------------------------------------------------------------------------------------------------

----MAIN ENTITY
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MD5_test is
    Port ( 
clk : in STD_LOGIC;
configreg : in STD_LOGIC_VECTOR(31 downto 0);
hashin1 : in STD_LOGIC_VECTOR(31 downto 0);
hashin2 : in STD_LOGIC_VECTOR(31 downto 0);
hashin3 : in STD_LOGIC_VECTOR(31 downto 0);
hashin4 : in STD_LOGIC_VECTOR(31 downto 0);
outreg : out STD_LOGIC_VECTOR(31 downto 0);
passwdH : out STD_LOGIC_VECTOR(31 downto 0);
passwdL : out STD_LOGIC_VECTOR(31 downto 0)

);
end MD5_test;


architecture RTL of MD5_test is

signal target_md5hash : std_logic_vector(127 downto 0);  --hash for which pw is to be cracked
signal reset : std_logic;

type pwguess_type is array(0 to 25)of std_logic_vector(79 downto 0);
signal pw_guess : pwguess_type;

type pwdel_type is array(0 to 25)of std_logic_vector(79 downto 0);
signal pw_del, pw_del_reg : pwdel_type;

type hashgen_type is array(0 to 25)of std_logic_vector(127 downto 0);
signal md5hash_gen : hashgen_type;

signal got_pw : std_logic_vector(0 to 25):= (others => '0');
signal got_pw_sig: std_logic := '0';

signal pw_sig, pw_sig2 : std_logic_vector(31 downto 0):= (others => '0');

    component md5_core 
    port (
    clkin : in STD_LOGIC;
    reset : in STD_LOGIC;    
    din : in STD_LOGIC_VECTOR (79 downto 0);
    pw_del : out STD_LOGIC_VECTOR (79 downto 0);
    cvout : out STD_LOGIC_VECTOR (127 downto 0)
    );
    end component;    
    
    component pw_gen 
        Port ( 
    clk : in STD_LOGIC;    
    reset : in STD_LOGIC; 
    bl : in UNSIGNED(7 downto 0);
    pw_guess : out STD_LOGIC_VECTOR(79 downto 0)
    
    );
    end component;
    
 
begin --begin architecture

reset <= configreg(0);
target_md5hash <= hashin4 & hashin3 & hashin2 & hashin1;

------------------------- guess pw generation pw_guess -----------------------------------------------------------

PWGEN: for i in 0 to 12 generate --A 2 Z
U1: pw_gen port map (clk => clk, reset => reset, bl => to_unsigned(65+2*i, 8), pw_guess => pw_guess(i));
end generate PWGEN;
PWGEN2: for i in 0 to 12 generate --a 2 z
U2: pw_gen port map (clk => clk, reset => reset, bl => to_unsigned(97+2*i, 8), pw_guess => pw_guess(13+i));
end generate PWGEN2;
----------------------- End of guess pw generation---------------------------------------------------------------

------------------------- HASH GENERATION------------------------------------------------------------------------

HASHGEN: for i in 0 to 25 generate 
U3: md5_core port map (clkin => clk, reset => reset, din => pw_guess(i), pw_del => pw_del(i), cvout => md5hash_gen(i));
hash_compa : process(clk, reset)
    begin    
        if(reset = '1') then
            got_pw(i) <= '0';
            pw_del_reg(i) <= (others => '0');
        elsif rising_edge(clk) then
                if(md5hash_gen(i) = target_md5hash) then
                    got_pw(i) <= '1'; 
                    pw_del_reg(i) <= pw_del(i);        
                end if;
        end if;
end process; 
end generate HASHGEN;
------------------------ END OF HASH GENERATION ------------------------------------------------------------------- 

--FSM8
pw_gotpw : process(clk, reset)
    begin    
        if(reset = '1') then
            outreg(0) <= '0';
            pw_sig  <= (others => '0');
            pw_sig2 <= (others => '0');
        elsif rising_edge(clk) then
            for i in 0 to 25 loop
                if(got_pw(i)='1') then
                    outreg(0) <= '1';
                    pw_sig    <= pw_del_reg(i)(79 downto 48);
                    pw_sig2   <= pw_del_reg(i)(47 downto 16);                                                
                end if;
            end loop;
        end if;
end process; 
      
--outputs       
outreg(31 downto 1) <= (others => '0');

passwdH  <= pw_sig;
passwdL  <= pw_sig2;  

end RTL;