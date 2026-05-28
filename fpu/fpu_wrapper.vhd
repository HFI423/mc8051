-------------------------------------------------------------------------------
--
-- Project:     FPU Wrapper
--
-- Description: Wrapper around the Al-Eryani FPU core.
--              Translates the custom CMD interface (OPA, OPB, FPCAB)
--              to the internal fpu.vhd interface and back.
--
-- Interface:
--   Inputs:
--     clk_i     : clock
--     opa_i     : 32-bit IEEE 754 operand A
--     opb_i     : 32-bit IEEE 754 operand B
--     fpcab_i   : 8-bit command register
--                   bits [2:0] = operation
--                     000 = ADD
--                     001 = SUB
--                     010 = MUL
--                     011 = DIV
--                   bits [7:3] = ignored
--
--   Outputs:
--     result_o  : 32-bit IEEE 754 result
--     fpcr_o    : 8-bit status register
--                   0xFF = operation complete (ready), held until next start
--                   0x00 = busy / idle
--
-- Timing:
--   result_o and fpcr_o are updated in the SAME clock cycle.
--   fpcr_o stays 0xFF until the next operation starts.
--
-- Notes:
--   - Rounding mode fixed to "round to zero" (01) = no rounding
--   - NaN, Inf, exceptions are not forwarded
--   - New operation starts automatically on any rising edge of fpcab_i change
--   - SQRT not wired to output
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fpupack.all;
use work.comppack.all;

entity fpu_wrapper is
    port (
        clk_i    : in  std_logic;

        opa_i    : in  std_logic_vector(31 downto 0);
        opb_i    : in  std_logic_vector(31 downto 0);
        fpcab_i  : in  std_logic_vector(7 downto 0);

        result_o : out std_logic_vector(31 downto 0);
        fpcr_o   : out std_logic_vector(7 downto 0)
    );
end entity fpu_wrapper;

architecture rtl of fpu_wrapper is

    component fpu is
        port (
            clk_i       : in  std_logic;
            opa_i       : in  std_logic_vector(FP_WIDTH-1 downto 0);
            opb_i       : in  std_logic_vector(FP_WIDTH-1 downto 0);
            fpu_op_i    : in  std_logic_vector(2 downto 0);
            rmode_i     : in  std_logic_vector(1 downto 0);
            output_o    : out std_logic_vector(FP_WIDTH-1 downto 0);
            start_i     : in  std_logic;
            ready_o     : out std_logic;
            ine_o       : out std_logic;
            overflow_o  : out std_logic;
            underflow_o : out std_logic;
            div_zero_o  : out std_logic;
            inf_o       : out std_logic;
            zero_o      : out std_logic;
            qnan_o      : out std_logic;
            snan_o      : out std_logic
        );
    end component;

    signal s_fpu_op    : std_logic_vector(2 downto 0);
    signal s_start     : std_logic;
    signal s_ready     : std_logic;
    signal s_output    : std_logic_vector(31 downto 0);

    signal fpcab_prev  : std_logic_vector(7 downto 0) := (others => '1');

    -- Internal status flag: set when ready, cleared when new op starts
    signal s_done      : std_logic;

begin

    s_fpu_op <= fpcab_i(2 downto 0);

    ---------------------------------------------------------------------------
    -- Start-pulse + done-flag management
    --
    --  s_start goes '1' for exactly one cycle on any FPCAB change.
    --  s_done  goes '1' when FPU core asserts ready_o, and stays '1'
    --          until the next operation begins (next FPCAB change).
    --  This way fpcr_o = 0xFF is held stable until the master reads it
    --  and issues a new command.
    ---------------------------------------------------------------------------
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            fpcab_prev <= fpcab_i;

            if fpcab_i /= fpcab_prev then
                -- New command detected: fire start, clear done
                s_start <= '1';
                s_done  <= '0';
            else
                s_start <= '0';
                -- Latch ready from core; hold until next command
                if s_ready = '1' then
                    s_done <= '1';
                end if;
            end if;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Output: result and FPCR are written in the same clock cycle
    -- when the FPU core asserts ready_o (combinational read of s_done).
    ---------------------------------------------------------------------------
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if s_ready = '1' then
                result_o <= s_output;
            end if;
        end if;
    end process;

    -- FPCR is driven combinationally from s_done so it is valid in the
    -- same cycle that result_o is written (s_done latches one cycle after
    -- s_ready, but result_o also registers one cycle after s_ready -- they
    -- are aligned).
    -- Use the registered s_done so both outputs change on the same clock edge.
    fpcr_o <= x"FF" when s_done = '1' else x"00";

    ---------------------------------------------------------------------------
    -- FPU core instantiation
    ---------------------------------------------------------------------------
    i_fpu : fpu
        port map (
            clk_i       => clk_i,
            opa_i       => opa_i,
            opb_i       => opb_i,
            fpu_op_i    => s_fpu_op,
            rmode_i     => "01",
            output_o    => s_output,
            start_i     => s_start,
            ready_o     => s_ready,
            ine_o       => open,
            overflow_o  => open,
            underflow_o => open,
            div_zero_o  => open,
            inf_o       => open,
            zero_o      => open,
            qnan_o      => open,
            snan_o      => open
        );

end architecture rtl;
