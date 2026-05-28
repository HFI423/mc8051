-------------------------------------------------------------------------------
--
-- Project:     FPU Wrapper Testbench (erweitert, VHDL 93)
--
-- 22 Testfaelle fuer ADD / SUB / MUL / DIV.
-- Deckt ab: Vorzeichenwechsel, Null-Operanden, gleiche Zahlen,
-- negative Ergebnisse, Brueche, grosse/kleine Wertepaare.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fpu_wrapper is
end entity tb_fpu_wrapper;

architecture rtl of tb_fpu_wrapper is

    component fpu_wrapper is
        port (
            clk_i    : in  std_logic;
            opa_i    : in  std_logic_vector(31 downto 0);
            opb_i    : in  std_logic_vector(31 downto 0);
            fpcab_i  : in  std_logic_vector(7 downto 0);
            result_o : out std_logic_vector(31 downto 0);
            fpcr_o   : out std_logic_vector(7 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 10 ns;

    signal clk    : std_logic := '0';
    signal opa    : std_logic_vector(31 downto 0) := (others => '0');
    signal opb    : std_logic_vector(31 downto 0) := (others => '0');
    signal fpcab  : std_logic_vector(7 downto 0)  := x"FF";
    signal result : std_logic_vector(31 downto 0);
    signal fpcr   : std_logic_vector(7 downto 0);

    constant OP_ADD : std_logic_vector(7 downto 0) := x"00";
    constant OP_SUB : std_logic_vector(7 downto 0) := x"01";
    constant OP_MUL : std_logic_vector(7 downto 0) := x"02";
    constant OP_DIV : std_logic_vector(7 downto 0) := x"03";

begin

    clk <= not clk after CLK_PERIOD / 2;

    i_dut : fpu_wrapper
        port map (
            clk_i    => clk,
            opa_i    => opa,
            opb_i    => opb,
            fpcab_i  => fpcab,
            result_o => result,
            fpcr_o   => fpcr
        );

    ---------------------------------------------------------------------------
    stimulus : process

        variable v_pass : integer := 0;
        variable v_run  : integer := 0;

        procedure run_test (
            test_nr  : in integer;
            op       : in std_logic_vector(7 downto 0);
            a        : in std_logic_vector(31 downto 0);
            b        : in std_logic_vector(31 downto 0);
            expected : in std_logic_vector(31 downto 0)
        ) is
        begin
            v_run := v_run + 1;

            opa   <= a;
            opb   <= b;
            fpcab <= op;

            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);

            wait until fpcr = x"FF";
            wait until rising_edge(clk);

            if result = expected then
                v_pass := v_pass + 1;
                report "  PASS  Test " & integer'image(test_nr);
            else
                report "  FAIL  Test " & integer'image(test_nr) &
                       "  erwartet=" &
                       integer'image(to_integer(unsigned(expected))) &
                       "  erhalten=" &
                       integer'image(to_integer(unsigned(result)))
                severity FAILURE;
            end if;

            fpcab <= x"FF";
            wait until rising_edge(clk);
            wait until rising_edge(clk);
        end procedure;

    begin

        report "================================================";
        report "FPU Wrapper Testbench gestartet";
        report "================================================";
        wait for CLK_PERIOD * 5;

        -- ----------------------------------------------------------------
        report "--- ADD ---";
        -- ----------------------------------------------------------------

        report "Test  1: -5.0 + 5.0 = 0.0  (Ausloeschung)";
        run_test( 1, OP_ADD, x"C0A00000", x"40A00000", x"00000000");

        report "Test  2: -3.5 + (-1.25) = -4.75  (neg + neg)";
        run_test( 2, OP_ADD, x"C0600000", x"BFA00000", x"C0980000");

        report "Test  3: 0.0001 + 10000.0 = 10000.0  (Praezisionsverlust)";
        run_test( 3, OP_ADD, x"38D1B717", x"461C4000", x"461C4000");

        report "Test  4: 7.0 + 7.0 = 14.0  (Verdoppelung)";
        run_test( 4, OP_ADD, x"40E00000", x"40E00000", x"41600000");

        report "Test  5: 0.0 + 42.0 = 42.0  (Null-Identitaet)";
        run_test( 5, OP_ADD, x"00000000", x"42280000", x"42280000");

        -- ----------------------------------------------------------------
        report "--- SUB ---";
        -- ----------------------------------------------------------------

        report "Test  6: 3.0 - 9.0 = -6.0  (Ergebnis negativ)";
        run_test( 6, OP_SUB, x"40400000", x"41100000", x"C0C00000");

        report "Test  7: -2.0 - (-8.0) = 6.0  (neg minus neg = pos)";
        run_test( 7, OP_SUB, x"C0000000", x"C1000000", x"40C00000");

        report "Test  8: 5.5 - 5.5 = 0.0  (Ausloeschung)";
        run_test( 8, OP_SUB, x"40B00000", x"40B00000", x"00000000");

        report "Test  9: 1024.0 - 0.5 = 1023.5  (gross minus winzig, exakt)";
        run_test( 9, OP_SUB, x"44800000", x"3F000000", x"447FE000");

        report "Test 10: 0.0 - 7.25 = -7.25  (Null minus Zahl)";
        run_test(10, OP_SUB, x"00000000", x"40E80000", x"C0E80000");

        -- ----------------------------------------------------------------
        report "--- MUL ---";
        -- ----------------------------------------------------------------

        report "Test 11: 6.0 * (-3.0) = -18.0  (pos * neg)";
        run_test(11, OP_MUL, x"40C00000", x"C0400000", x"C1900000");

        report "Test 12: -4.0 * (-4.0) = 16.0  (neg * neg = pos)";
        run_test(12, OP_MUL, x"C0800000", x"C0800000", x"41800000");

        report "Test 13: 99999.0 * 0.0 = 0.0  (mal Null)";
        run_test(13, OP_MUL, x"47C34F80", x"00000000", x"00000000");

        report "Test 14: 123.456 * 1.0 = 123.456  (Einselement)";
        run_test(14, OP_MUL, x"42F6E979", x"3F800000", x"42F6E979");

        report "Test 15: 0.5 * 0.25 = 0.125  (Bruch * Bruch)";
        run_test(15, OP_MUL, x"3F000000", x"3E800000", x"3E000000");

        report "Test 16: -7.5 * 1.0 = -7.5  (neg * Eins unveraendert)";
        run_test(16, OP_MUL, x"C0F00000", x"3F800000", x"C0F00000");

        -- ----------------------------------------------------------------
        report "--- DIV ---";
        -- ----------------------------------------------------------------

        report "Test 17: -9.0 / 3.0 = -3.0  (neg / pos)";
        run_test(17, OP_DIV, x"C1100000", x"40400000", x"C0400000");

        report "Test 18: 9.0 / (-3.0) = -3.0  (pos / neg)";
        run_test(18, OP_DIV, x"41100000", x"C0400000", x"C0400000");

        report "Test 19: -9.0 / (-3.0) = 3.0  (neg / neg = pos)";
        run_test(19, OP_DIV, x"C1100000", x"C0400000", x"40400000");

        report "Test 20: 42.0 / 1.0 = 42.0  (durch Eins)";
        run_test(20, OP_DIV, x"42280000", x"3F800000", x"42280000");

        report "Test 21: 1.0 / 4.0 = 0.25  (Ergebnis kleiner 1)";
        run_test(21, OP_DIV, x"3F800000", x"40800000", x"3E800000");

        report "Test 22: 1000.0 / 0.125 = 8000.0  (gross / klein)";
        run_test(22, OP_DIV, x"447A0000", x"3E000000", x"45FA0000");

        -- ----------------------------------------------------------------
        report "================================================";
        report "Ergebnis: " & integer'image(v_pass) &
               " / " & integer'image(v_run) & " Tests bestanden";
        report "================================================";

        assert v_pass = v_run
            report "EINIGE TESTS FEHLGESCHLAGEN!"
            severity FAILURE;

        assert false
            report "Simulation erfolgreich abgeschlossen."
            severity FAILURE;

        wait;
    end process stimulus;

end architecture rtl;
