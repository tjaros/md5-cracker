library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package global_consts is

-- T[] matrix is a constant of 64 x 32-bit vectors 
--*** ORDER of elements is IMP 
type vect_T_type is array (0 to 63)of std_logic_vector(31 downto 0); --first element is 0th element
constant vect_T : vect_T_type :=
                               (x"d76aa478",x"e8c7b756",x"242070db",x"c1bdceee",x"f57c0faf",x"4787c62a",x"a8304613",x"fd469501",
 						        x"698098d8",x"8b44f7af",x"ffff5bb1",x"895cd7be",x"6b901122",x"fd987193",x"a679438e",x"49b40821", 
 						        x"f61e2562",x"c040b340",x"265e5a51",x"e9b6c7aa",x"d62f105d",x"02441453",x"d8a1e681",x"e7d3fbc8", 
 						        x"21e1cde6",x"c33707d6",x"f4d50d87",x"455a14ed",x"a9e3e905",x"fcefa3f8",x"676f02d9",x"8d2a4c8a", 
                                x"fffa3942",x"8771f681",x"6d9d6122",x"fde5380c",x"a4beea44",x"4bdecfa9",x"f6bb4b60",x"bebfbc70", 
 						        x"289b7ec6",x"eaa127fa",x"d4ef3085",x"04881d05",x"d9d4d039",x"e6db99e5",x"1fa27cf8",x"c4ac5665", 
 						        x"f4292244",x"432aff97",x"ab9423a7",x"fc93a039",x"655b59c3",x"8f0ccc92",x"ffeff47d",x"85845dd1", 
 						        x"6fa87e4f",x"fe2ce6e0",x"a3014314",x"4e0811a1",x"f7537e82",x"bd3af235",x"2ad7d2bb",x"eb86d391"); 						        

 --shift vector
 --*** ORDER of elements is IMP
 type SHIFT_S is array (0 to 3) of integer range 4 to 23;
 constant s1: SHIFT_S:= (7, 12, 17, 22);
 constant s2: SHIFT_S:= (5, 9, 14, 20);
 constant s3: SHIFT_S:= (4, 11, 16, 23);
 constant s4: SHIFT_S:= (6, 10, 15, 21);
 
end package global_consts;


--md5_stage1
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.global_consts.all;

entity md5_stage1 is
port(i : in INTEGER;
    reset : in STD_LOGIC;
    clkin : in STD_LOGIC;
    iv : in STD_LOGIC_VECTOR (127 downto 0);
    din : in STD_LOGIC_VECTOR (79 downto 0);
    din_out : out STD_LOGIC_VECTOR (79 downto 0);
    cvout : out STD_LOGIC_VECTOR (127 downto 0)
);
end md5_stage1;

architecture rtl of md5_stage1 is

--*** ORDER of elements is IMP
alias A_vect : std_logic_vector(31 downto 0) is iv(127 downto 96);
alias B_vect : std_logic_vector(31 downto 0) is iv(95 downto 64);
alias C_vect : std_logic_vector(31 downto 0) is iv(63 downto 32);
alias D_vect : std_logic_vector(31 downto 0) is iv(31 downto 0);

type vect_X_type is array(0 to 15)of std_logic_vector(31 downto 0);
signal vect_X : vect_X_type;

begin

vect_X <= vect_X_type'( din(79 downto 48), din(47 downto 16),  x"000000"&din(15 downto 8), x"0000_0000",
                     x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", 
                     x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"000000"&din(7 downto 0), x"0000_0000");                     
                     
---------------------------------------------------------------------------------------------------------------------------
    fsm_stg1 : process(clkin, reset)
    
    variable vect_B1_bit : bit_vector(31 downto 0);
    variable vect_B33, vect_B33_2 : std_logic_vector(32 downto 0);
    variable tmp_A, vect_B1, vect_f : std_logic_vector(31 downto 0);
    variable A_reg, B_reg, C_reg, D_reg : std_logic_vector(31 downto 0);    
    
    begin    
            if(reset = '1') then 
                A_reg := (others => '0');
                B_reg := (others => '0');
                C_reg := (others => '0');
                D_reg := (others => '0');
                cvout <= (others => '0');   
                
            elsif rising_edge(clkin) then
                vect_f := (B_vect and C_vect) or (not(B_vect) and D_vect);  --F                     
                tmp_A := A_vect;
                A_reg := D_vect;
                D_reg := C_vect;
                C_reg := B_vect; 
                --addition in modulo; in a = b mod 20, both a and b has to be integers           
                vect_B33 := std_logic_vector(unsigned('0'&tmp_A)+ unsigned('0'&vect_f)+ unsigned('0'&vect_X(i))+ unsigned('0'&vect_T(i)));           
                vect_B1_bit := to_bitvector(vect_B33(31 downto 0));
                --circular rotate left; a rol 10, 'a' should be type bitvector  
                vect_B1 := to_stdlogicvector(vect_B1_bit rol (s1(i mod 4)));  
                --add it to vect_B 
                vect_B33_2 := std_logic_vector(unsigned('0'&B_vect) + unsigned('0'&vect_B1));
                B_reg := vect_B33_2(31 downto 0); 
                
                cvout <= A_reg & B_reg & C_reg & D_reg;
                
            end if;
                
end process;                
---------------------------------------------------------------------------------------------------------------------------

--Delaying the din for the sake of pipelining: 
din_proc : process(clkin, reset)
    begin
        if(reset = '1') then         
            din_out <= (others =>'0'); 
        elsif rising_edge(clkin) then
            din_out <= din;            
        end if;
end process; 

end rtl;


--md5_stage2
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.global_consts.all;

entity md5_stage2 is
port(j : in INTEGER;
    reset : in STD_LOGIC;
    clkin : in STD_LOGIC;
    cvin : in STD_LOGIC_VECTOR (127 downto 0);
    din : in STD_LOGIC_VECTOR (79 downto 0);
    din_out : out STD_LOGIC_VECTOR (79 downto 0);
    cvout : out STD_LOGIC_VECTOR (127 downto 0)
);
end md5_stage2;

architecture rtl of md5_stage2 is

--*** ORDER of elements is IMP
alias A_vect : std_logic_vector(31 downto 0) is cvin(127 downto 96);
alias B_vect : std_logic_vector(31 downto 0) is cvin(95 downto 64);
alias C_vect : std_logic_vector(31 downto 0) is cvin(63 downto 32);
alias D_vect : std_logic_vector(31 downto 0) is cvin(31 downto 0);

type vect_X_type is array(0 to 15)of std_logic_vector(31 downto 0);
signal vect_X : vect_X_type;


begin
 
vect_X <= vect_X_type'( din(79 downto 48), din(47 downto 16),  x"000000"&din(15 downto 8), x"0000_0000",
                     x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", 
                     x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"000000"&din(7 downto 0), x"0000_0000");                    
                     
---------------------------------------------------------------------------------------------------------------------------
    fsm_stg2 : process(clkin, reset)
    
    variable vect_B1_bit : bit_vector(31 downto 0);
    variable vect_B33, vect_B33_2 : std_logic_vector(32 downto 0);
    variable tmp_A, vect_B1, vect_g : std_logic_vector(31 downto 0);
    variable A_reg, B_reg, C_reg, D_reg : std_logic_vector(31 downto 0); 
    
    begin    
            if(reset = '1') then
                A_reg := (others => '0');
                B_reg := (others => '0');
                C_reg := (others => '0');
                D_reg := (others => '0');            
                cvout <= (others => '0');  
                
            elsif rising_edge(clkin) then
                vect_g := (B_vect and D_vect) or (C_vect and (not(D_vect))); --G
                tmp_A := A_vect;
                A_reg := D_vect;
                D_reg := C_vect;
                C_reg := B_vect;                                   
                vect_B33 := std_logic_vector(unsigned('0'&tmp_A)+ unsigned('0'&vect_g)+ unsigned('0'&vect_X((5*j+1) mod 16))+ unsigned('0'&vect_T(j+16)));
                vect_B1_bit := to_bitvector(vect_B33(31 downto 0));             
                vect_B1 := to_stdlogicvector(vect_B1_bit rol (s2(j mod 4)));
                vect_B33_2 := std_logic_vector(unsigned('0'&B_vect) + unsigned('0'&vect_B1));
                B_reg := vect_B33_2(31 downto 0); 

                cvout <= A_reg & B_reg & C_reg & D_reg;
                 
            end if;
                
end process;                
---------------------------------------------------------------------------------------------------------------------------

--Delaying the din for the sake of pipelining: 
din_proc2 : process(clkin, reset)
    begin
        if(reset = '1') then         
            din_out <= (others =>'0'); 
        elsif rising_edge(clkin) then
            din_out <= din;            
        end if;
end process; 

end rtl;

--md5_stage3
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.global_consts.all;

entity md5_stage3 is
port(k : in INTEGER;
    reset : in STD_LOGIC;
    clkin : in STD_LOGIC;
    cvin : in STD_LOGIC_VECTOR (127 downto 0);
    din : in STD_LOGIC_VECTOR (79 downto 0);
    din_out : out STD_LOGIC_VECTOR (79 downto 0);
    cvout : out STD_LOGIC_VECTOR (127 downto 0)
);
end md5_stage3;

architecture rtl of md5_stage3 is

--*** ORDER of elements is IMP
alias A_vect : std_logic_vector(31 downto 0) is cvin(127 downto 96);
alias B_vect : std_logic_vector(31 downto 0) is cvin(95 downto 64);
alias C_vect : std_logic_vector(31 downto 0) is cvin(63 downto 32);
alias D_vect : std_logic_vector(31 downto 0) is cvin(31 downto 0);

type vect_X_type is array(0 to 15)of std_logic_vector(31 downto 0);
signal vect_X : vect_X_type;


begin

vect_X <= vect_X_type'( din(79 downto 48), din(47 downto 16),  x"000000"&din(15 downto 8), x"0000_0000",
                     x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", 
                     x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"000000"&din(7 downto 0), x"0000_0000");                      
                     
---------------------------------------------------------------------------------------------------------------------------
    fsm_stg3 : process(clkin, reset)
    
    variable vect_B1_bit : bit_vector(31 downto 0);
    variable vect_B33, vect_B33_2 : std_logic_vector(32 downto 0);
    variable tmp_A, vect_B1, vect_h : std_logic_vector(31 downto 0);
    variable A_reg, B_reg, C_reg, D_reg : std_logic_vector(31 downto 0); 
    
    begin    
            if(reset = '1') then
                A_reg := (others => '0');
                B_reg := (others => '0');
                C_reg := (others => '0');
                D_reg := (others => '0');
                cvout <= (others => '0'); 
                
            elsif rising_edge(clkin) then
                    vect_h := B_vect xor C_vect xor D_vect; --H
                    tmp_A := A_vect;
                    A_reg := D_vect;
                    D_reg := C_vect;
                    C_reg := B_vect;  
                    vect_B33 := std_logic_vector(unsigned('0'&tmp_A)+ unsigned('0'&vect_h)+ unsigned('0'&vect_X((3*k+5) mod 16))+ unsigned('0'&vect_T(k+32)));
                    vect_B1_bit := to_bitvector(vect_B33(31 downto 0));             
                    vect_B1 := to_stdlogicvector(vect_B1_bit rol (s3(k mod 4)));
                    vect_B33_2 := std_logic_vector(unsigned('0'&B_vect) + unsigned('0'&vect_B1));
                    B_reg := vect_B33_2(31 downto 0);

                    cvout <= A_reg & B_reg & C_reg & D_reg;

            end if;
                
end process;                
---------------------------------------------------------------------------------------------------------------------------

--Delaying the din for the sake of pipelining: 
din_proc3 : process(clkin, reset)
    begin
        if(reset = '1') then         
            din_out <= (others =>'0'); 
        elsif rising_edge(clkin) then
            din_out <= din;            
        end if;
end process; 

end rtl;

--md5_stage4
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.global_consts.all;

entity md5_stage4 is
port(l : in INTEGER;
    reset : in STD_LOGIC;
    clkin : in STD_LOGIC;
    cvin : in STD_LOGIC_VECTOR (127 downto 0);
    din : in STD_LOGIC_VECTOR (79 downto 0);
    din_out : out STD_LOGIC_VECTOR (79 downto 0);
    cvout : out STD_LOGIC_VECTOR (127 downto 0)
);
end md5_stage4;

architecture rtl of md5_stage4 is

--*** ORDER of elements is IMP
alias A_vect : std_logic_vector(31 downto 0) is cvin(127 downto 96);
alias B_vect : std_logic_vector(31 downto 0) is cvin(95 downto 64);
alias C_vect : std_logic_vector(31 downto 0) is cvin(63 downto 32);
alias D_vect : std_logic_vector(31 downto 0) is cvin(31 downto 0);

type vect_X_type is array(0 to 15)of std_logic_vector(31 downto 0);
signal vect_X : vect_X_type;

begin

vect_X <= vect_X_type'( din(79 downto 48), din(47 downto 16), x"000000"&din(15 downto 8), x"0000_0000",
                     x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", 
                     x"0000_0000", x"0000_0000", x"0000_0000", x"0000_0000", x"000000"&din(7 downto 0), x"0000_0000");                    
                     
---------------------------------------------------------------------------------------------------------------------------
    fsm_stg4 : process(clkin, reset)
    
    variable vect_B1_bit : bit_vector(31 downto 0);
    variable vect_B33, vect_B33_2 : std_logic_vector(32 downto 0);
    variable tmp_A, vect_B1, vect_i : std_logic_vector(31 downto 0);
    variable A_reg, B_reg, C_reg, D_reg : std_logic_vector(31 downto 0); 
    
    begin    
            if(reset = '1') then
                A_reg := (others => '0');
                B_reg := (others => '0');
                C_reg := (others => '0');
                D_reg := (others => '0');
                cvout <= (others => '0'); 
                
            elsif rising_edge(clkin) then 
                    vect_i := C_vect xor ( B_vect or (not(D_vect))); --I
                    tmp_A := A_vect;
                    A_reg := D_vect;
                    D_reg := C_vect;
                    C_reg := B_vect;  
                    vect_B33 := std_logic_vector(unsigned('0'&tmp_A)+ unsigned('0'&vect_i)+ unsigned('0'&vect_X((7*l) mod 16))+ unsigned('0'&vect_T(l+48)));
                    vect_B1_bit := to_bitvector(vect_B33(31 downto 0));    
                    vect_B1 := to_stdlogicvector(vect_B1_bit rol (s4(l mod 4))); 
                    vect_B33_2 := std_logic_vector(unsigned('0'&B_vect) + unsigned('0'&vect_B1));
                    B_reg := vect_B33_2(31 downto 0); 

                    cvout <= A_reg & B_reg & C_reg & D_reg;
            end if;
                
end process;                
---------------------------------------------------------------------------------------------------------------------------

--Delaying the din for the sake of pipelining: 
din_proc4 : process(clkin, reset)
    begin
        if(reset = '1') then         
            din_out <= (others =>'0'); 
        elsif rising_edge(clkin) then
            din_out <= din;            
        end if;
end process; 

end rtl;

--------------------------------------- MAIN ENTITY -----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity md5_core is
port (
    clkin : in STD_LOGIC; 
    reset : in STD_LOGIC;
    din   : in STD_LOGIC_VECTOR (79 downto 0); 
    pw_del : out STD_LOGIC_VECTOR (79 downto 0);   
    cvout : out STD_LOGIC_VECTOR (127 downto 0)
    );

end md5_core;


architecture RTL of md5_core is

component md5_stage1
    port(
        i : in INTEGER;
        reset : in STD_LOGIC; 
        clkin : in STD_LOGIC;
        iv : in STD_LOGIC_VECTOR (127 downto 0);
        din : in STD_LOGIC_VECTOR (79 downto 0);
        din_out : out STD_LOGIC_VECTOR (79 downto 0);
        cvout : out STD_LOGIC_VECTOR (127 downto 0));
    end component;
    

component md5_stage2
    port(
        j : in INTEGER;
        reset : in STD_LOGIC; 
        clkin : in STD_LOGIC;
        cvin : in STD_LOGIC_VECTOR (127 downto 0);
        din : in STD_LOGIC_VECTOR (79 downto 0);
        din_out : out STD_LOGIC_VECTOR (79 downto 0);
        cvout : out STD_LOGIC_VECTOR (127 downto 0));
    end component;  
    
    
component md5_stage3
    port(
        k : in INTEGER;
        reset : in STD_LOGIC; 
        clkin : in STD_LOGIC;
        cvin : in STD_LOGIC_VECTOR (127 downto 0);
        din : in STD_LOGIC_VECTOR (79 downto 0);
        din_out : out STD_LOGIC_VECTOR (79 downto 0);
        cvout : out STD_LOGIC_VECTOR (127 downto 0));
    end component;  
    
    
component md5_stage4
    port(
        l : in INTEGER;
        reset : in STD_LOGIC; 
        clkin : in STD_LOGIC;
        cvin : in STD_LOGIC_VECTOR (127 downto 0);
        din : in STD_LOGIC_VECTOR (79 downto 0);
        din_out : out STD_LOGIC_VECTOR (79 downto 0);
        cvout : out STD_LOGIC_VECTOR (127 downto 0));
    end component;     

--*** ORDER of elements is IMP
constant InitialVect : std_logic_vector(127 downto 0) := x"67452301efcdab8998badcfe10325476"; --this is correct

signal temp_cvout129 : std_logic_vector(128 downto 0):= (others => '0');

type cvin_type is array(0 to 63)of std_logic_vector(127 downto 0);
signal temp_cvin : cvin_type;
type din_type is array(0 to 64)of std_logic_vector(79 downto 0);
signal din_out : din_type;

signal A_reg33, B_reg33, C_reg33, D_reg33 : std_logic_vector(32 downto 0):= (others => '0');

begin

U0: md5_stage1 port map (i => 0, reset => reset, clkin => clkin, iv => InitialVect, din => din, din_out => din_out(0), cvout => temp_cvin(0));
GEN1: for i in 1 to 15 generate 
U1: md5_stage1 port map (i => i, reset => reset, clkin => clkin, iv => temp_cvin(i-1), din => din_out(i-1), din_out => din_out(i), cvout => temp_cvin(i));
end generate GEN1;
GEN2: for i in 0 to 15 generate
U2: md5_stage2 port map (j => i, reset => reset, clkin => clkin, cvin => temp_cvin(16+i-1), din => din_out(15+i), din_out => din_out(16+i), cvout => temp_cvin(16+i));
end generate GEN2;
GEN3: for i in 0 to 15 generate
U3: md5_stage3 port map (k => i, reset => reset, clkin => clkin, cvin => temp_cvin(32+i-1), din => din_out(31+i), din_out => din_out(32+i), cvout => temp_cvin(32+i));
end generate GEN3;
GEN4: for i in 0 to 15 generate
U3: md5_stage4 port map (l => i, reset => reset, clkin => clkin, cvin => temp_cvin(48+i-1), din => din_out(47+i), din_out => din_out(48+i), cvout => temp_cvin(48+i));
end generate GEN4;
 
 --add vectors of A, B, C and D to their original values 
   A_reg33 <= std_logic_vector(unsigned('0'& temp_cvin(63)(127 downto 96)) + unsigned('0'& InitialVect(127 downto 96)));
   B_reg33 <= std_logic_vector(unsigned('0'& temp_cvin(63)(95 downto 64)) + unsigned('0'& InitialVect(95 downto 64)));
   C_reg33 <= std_logic_vector(unsigned('0'& temp_cvin(63)(63 downto 32)) + unsigned('0'& InitialVect(63 downto 32)));
   D_reg33 <= std_logic_vector(unsigned('0'& temp_cvin(63)(31 downto 0)) + unsigned('0'& InitialVect(31 downto 0)));
      

--Digest should begin with low-order byte of A and end with high-order byte of D.
--*** ORDER of elements is IMP; 
    
cvout <=    A_reg33(7 downto 0) & A_reg33(15 downto 8) & A_reg33(23 downto 16) & A_reg33(31 downto 24)&
            B_reg33(7 downto 0) & B_reg33(15 downto 8) & B_reg33(23 downto 16) & B_reg33(31 downto 24)&
            C_reg33(7 downto 0) & C_reg33(15 downto 8) & C_reg33(23 downto 16) & C_reg33(31 downto 24)&
            D_reg33(7 downto 0) & D_reg33(15 downto 8) & D_reg33(23 downto 16) & D_reg33(31 downto 24); 

pw_del <= din_out(63);                
         
end RTL;