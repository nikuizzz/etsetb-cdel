# Module 2 (Keypad analyzer) - resources for writing the report

Working notes, not the report. Everything the report needs, in one place. Detailed explanations with figures are in `presentation-guide.html` (section numbers below refer to it).

Status: everything below compiles in Quartus II 9.1 (EP2C35F672C6). Board tests: parts of 3.4/3.5 were tested in the lab (see section 7); the changes made after the lab (keypad clock q[10], config-mode fixes) are **not yet re-tested on the board**.

## 1. What the handout asks for (deliverables) and where each one is

| Handout | What to deliver | Where / state |
|---|---|---|
| 3.1 part1 | compilation report, explanation of how the reader works, design fault + alternative, all .vwf | `part1.vhd`, `count10b.vhd`; .vwf: `part1-first-simulation.vwf`, `part1-contact-bounce-simulation.vwf` (+ corrected simulation to redo); LaTeX chapter `latex/module-2/chapter1.tex` (not in git); compile report of revision `cdel-module-2` (see section 6) |
| 3.2 part2 | compilation report, explanation (good / locked LEDs, can wrong sequences be corrected?), .vwf | `part2.vhd` (teacher's, unchanged). **Simulations still to do** (section 5) |
| 3.3 full system | .vhd/.bdf, compilation report (.rpt), .vwf simulations | `keypad.vhd` (revision `keypad`). **Simulations still to do** |
| 3.4 DE2 board | all project files of the adapted version, detailed description of the modifications | `keypad_de2.vhd` (revision `keypad_de2`), `clock_div.vhd`, `clk_lock.v`, `hex_disps.vhd`, `BCD7seg.vhd`, pin assignments |
| 3.5 improvements | all project files, explanation, all .vwf simulations | revisions `keypad_de2_i1` .. `_i3` are the handout's improvements; `_i4`, `_i5` are extras (check with the "previous work 2" report which of 4/5 were announced) |

## 2. Everything that was done (chronological)

1. **part1 (3.1)**: keypad reader FSM `whatkey` (wait0, check0, kra0..kra3, wait1, check1). Two faults found and fixed:
   - *Contact bounce vs. look period*: original `count4b` gives `look` every 16 cycles = 16 us at 1 MHz, while the measured bounce on the scope is about 400 us (15 squares x 100 us). Result: repeated detections of one press. Fix: `count10b`, `look` every 1024 cycles (1024 us at 1 MHz, about 2.5x the bounce).
   - *Glitch on the outputs*: `key`/`keycode` were combinational (Mealy) and `colq` is stale during the first half of each `kra` state, so a static hazard appears on the outputs. Fix: output register `outreg` on the rising edge (+1 cycle latency, harmless for part2).
   - `colq` is registered on the **falling** edge (half a cycle for the keypad to answer the current row): do not move it to the rising edge.
   - Evidence: `part1-first-simulation.vwf`, `part1-contact-bounce-simulation.vwf`, corrected simulation (check0 at 1.024 ms, kra0 at 1.025 ms, key=1 / keycode=1 at 1.026 ms).
2. **part2 (3.2)**: teacher's file, unchanged (guide section 7).
3. **3.3**: `keypad.vhd` = part1 + part2, revision `keypad` (114 logic elements, 44 registers, 20 pins).
4. **3.4**: `keypad_de2.vhd`: `clock_div` + `CLK_LOCK` for the system clock, digit register + `hex_disps` for the 4 displays, LEDs (guide section 9).
5. **3.5**: improvement 1 (blink), 2 (LCD messages), 3 (trick mode); then extras 4 (LCD message for trick, logic moved into part2c) and 5 (code configuration, part2d).
6. **Lab findings and fixes after the board test** (guide sections 13-15): the keypad clock was moved from `q[8]` to `q[10]`; clear/restart rules of the config mode.

## 3. Revisions: files and what each adds

All revisions: device EP2C35F672C6, Quartus II 9.1 SP2, unused pins "as input tri-stated". Pin assignments from `DE2_pin_assignments.csv` (ROW[0..3] = N18, P18, G23, G24; COL[0..3] = K22, G25, H23, H24).

| Revision (top-level entity) | VHDL files specific to it | What it adds | Results at the snapshot compile (LE / regs / pins) |
|---|---|---|---|
| `cdel-module-2` (part1) | `part1.vhd`, `count10b.vhd` | 3.1 (part1 only) | 58 / 27 / 15 |
| `keypad` | `keypad.vhd` (+ `part2.vhd`) | 3.3 full system | 114 / 44 / 20 |
| `keypad_de2` | `keypad_de2.vhd` | 3.4 board adaptation | 174 / 72 / 96 |
| `keypad_de2_i1` | `keypad_de2_i1.vhd` | blink: red LEDs blink at 1 Hz when locked | 220 / 97 / 96 |
| `keypad_de2_i2` | `keypad_de2_i2.vhd`, `part2b.vhd`, `LCD_int.vhd` | 5 LCD messages (Press * / Enter PIN / Right / Wrong / Locked) | 353 / 136 / 109 |
| `keypad_de2_i3` | `keypad_de2_i3.vhd` | trick mode: any of A-D toggles it; shows 1248 and ignores the keypad | 384 / 137 / 109 |
| `keypad_de2_i4` | `keypad_de2_i4.vhd`, `part2c.vhd`, `LCD_int_i4.vhd` | message 6 "Trick mode on", trick logic moved into part2c | 397 / 137 / 109 |
| `keypad_de2_i5` | `keypad_de2_i5.vhd`, `part2d.vhd`, `LCD_int_i5.vhd` | code configuration (C), trick only on A, messages 6-9 | 520 / 182 / 109 |

The numbers come from the compile reports of git commit `5914e5d` (snapshot taken before the reports were cleaned). They are from before the last changes (`q[10]`, `clrnum`): **recompile every revision and take the final numbers from the new .rpt** (Flow Summary, plus Timing Analyzer for fmax if wanted).

## 4. Design facts needed to explain the system

### 4.1 Keypad and part1
- Keypad 4x4: rows driven 0 or Z (tristate), columns pulled up. Key = row/column crossing. Key code map: row0 = 1,2,3,A; row1 = 4,5,6,B; row2 = 7,8,9,C; row3 = *(E),0,#(F),D.
- Priority when two keys are pressed: same row -> lowest column; same column -> lowest row (rows scanned 0..3).
- wait1/check1 make a held key be reported once. kra3 has two exits (kpressed -> wait1; not kpressed -> wait0).

### 4.2 part2 (code 1 2 4 8)
- `bcdind` (digit 0-9) = key and (not kc(3) or (not kc(2) and not kc(1))); `astind` = `*` (E); `almind` = `#` (F).
- `seqdet` FSM: waiting, start, now1ok..now4ok, now1ko..now4ko, seqok, seqko. `good` flip-flop: set in seqok, cleared in start.
- `errcnt` FSM err0..err3: a wrong code advances, a right one returns to err0, err3 is absorbing (**locked until reset KEY0, by design**). bad1 = errcnt /= err0, bad2 = err2 or err3, bad3 = err3.
- `shift` = bcdind except in waiting/seqko.
- Question of the handout: a wrong sequence **cannot be corrected** inside the sequence (the detector goes on in the ko states until `#`); it can be restarted with `*`.
- LED mapping (board): LED_GREEN(8..0) = good (all 9 together); LED_RED: 6 left = bad1, 6 middle = bad2, 6 right = bad3; all blink when bad3 (improvement 1).

### 4.3 Clocks (3.4)
- `clock_div` (teacher's, lab 1): free-running 16-bit counter. `q[n]` has period 2^(n+1) cycles, f = 50e3 / 2^(n+1) kHz.
- `CLK_LOCK` (`clk_lock.v`, altclkctrl): functionally transparent, puts the derived clock on a global clock network (low skew).
- System clock `sclk = CLK_LOCK(q[10])`: 24.41 kHz (half period 20.5 us). `look` = 1024 cycles = **41.9 ms**.
- LCD clock `lclk = CLK_LOCK(q[15])`: 763 Hz (LCD_int sends one command per state without waiting; HD44780 needs ~37 us per command and 1.5 ms for clear; handout: slower than q[12]).
- 1 Hz blink: counter on the 50 MHz clock, 0..24999999, toggling `blink` (25,000,000 cycles = 0.5 s per half period, period 1 s; 24999999 because counting starts at 0).
- History: first `q[8]` (97.66 kHz) was used; changed to `q[10]` in all board revisions after the lab test (see 6.3 and guide section 15).

### 4.4 Digit register and displays
- 16-bit `num` = 4 nibbles -> HEX3..HEX0; `num <= num(11 downto 0) & keycode` on `shift` while `ndig < 4`; cleared (x"FFFF") by `*`. `BCD7seg` gives all segments off for codes > 9, so F = blank. HEX4..7 are tied to blank.
- Trick mode shows `correct_code` (x"1248" by default) instead of `num`.
- **Careful**: HEX displays cannot show codes above 9 (A-F). For debugging key codes, LEDs were used.

### 4.5 LCD (improvement 2)
- `LCD_int` (teacher's) writes 17 chars per message (counter 0..16; the 17th lands off-screen). Message table bases: 0, 16, 32, 48, 64, 80, 96, 112, 128.
- Handshake with `run`/`busy`: top level asserts `run` low (falling edge starts a write) when `shown_msg /= msg` and `busy = '0'`, keeps it low until `busy = '1'`. A message change during a write is not lost: `shown_msg` stays old until busy returns to 0.

| Msg | Text | Condition (priority, highest first) |
|---|---|---|
| 9 | Trick mode on | trick active |
| 8 | Configuration on | config states (C after a right code, up to 4 digits typed) |
| 7 | Config. applied | config_apply |
| 6 | Must be 4 digits | config_failed |
| 5 | System Locked | errcnt = err3 |
| 3 | Right Code! | seqok, or waiting with good = 1 |
| 4 | Wrong Code! | seqko, or waiting with wrong flag |
| 1 | Press * to start | waiting |
| 2 | Enter PIN Code | otherwise |

(i2/i3 only have messages 1-5; i4 adds 6 = "Trick mode on"; i5 uses the order in the table.)

### 4.6 Trick mode (improvement 3, 4, 5)
- i3: `abcdind` (A-D), T flip-flop `trick`, `key_eff = key and not trick` masks the detector and the digit register, display mux x"1248" when tricking.
- i4/i5: the trick logic lives in part2c / part2d (`trick` output); in i5 only **A** toggles it (C is used for the config mode).

### 4.7 Code configuration (improvement 5, part2d)
- Enter with **C**, only when `good_i = '1'` (after a right code, before the next `*`). Type 4 digits: each is stored in `new_code1..4` (digit N is captured in the state that precedes it). `#` validates (applies), `*` cancels. Fewer or more than 4 digits + `#` -> `config_failed` ("Must be 4 digits"); there `*` or `C` restart the configuration (`config_start`).
- The new code is copied into `code1..4` in `config_apply`; `code1..4` are reset to 1,2,4,8 by KEY0. The code is **not stored** after reset or power-off.
- `clrnum` (part2d output): clears the typed digits when a configuration (re)starts, so the displays are blank for the new digits. A `C` outside the config mode does nothing.

## 5. Simulations (.vwf) to produce for the report

Use a 1 MHz clock like the 3.1 lab (unless stated). Simulate **the revisions as compiled**.

1. 3.1 part1, corrected version: one key press without bounce (check0 at 1.024 ms, kra0..., `key`/`keycode`); one press with bounce (reported once); two keys (priority). Keep the first/bounce simulations as "before" evidence.
2. 3.2 part2: (a) right sequence `* 1 2 4 8 #` -> good = 1; (b) wrong sequence -> bad1; (c) three wrong sequences -> bad3 and locked, sequence ignored until reset; (d) `*` in the middle of a sequence restarts it; (e) a right code after one or two errors resets the counter.
3. 3.3 `keypad`: same scenarios, driven from the keypad columns (`col`) instead of key/keycode.
4. 3.5 improvement 1: with a fast count (or a reduced constant in a test copy) show `blink` toggling when bad3 = 1.
5. 3.5 improvement 2: `msg` sequence for the right and wrong cases; `run`/`busy` handshake with a fake `busy`.
6. 3.5 improvement 3 / 4: key `A` toggles `trick`; other keys ignored while tricking; `msg = 9`.
7. Improvement 5: `C` after a right code, 4 digits, `#`; then the new code accepted; error cases (3 digits + `#` -> msg 6; `*` -> config_start).

## 6. Compilation reports and lab measurements

### 6.1 Where the .rpt are
The `.rpt/.htm/.sof` files were cleaned from the working folder. They exist in git in the snapshot commit `5914e5d` (branch `snapshot-improvement-5-wip`): `git show 5914e5d:module-2/<revision>.flow.rpt` (same for `.map.rpt`, `.fit.rpt`, `.tan.rpt`). For the report, recompile each revision and keep the new Flow Summary, Fitter and Timing Analyzer summary.

### 6.2 Useful values already measured
- Timing analyzer, part1 (`cdel-module-2`): worst-case tsu 4.574 ns (col[1] -> colq[1]).
- Contact bounce measured with the oscilloscope: about 400 us (15 squares x 100 us).

### 6.3 Lab findings (board)
- Digits, code entry, LEDs, blink, LCD messages, trick mode, **worked** in the revisions tested in the lab (keypad_de2 to keypad_de2_i3 reported as working by the user; i4 and i5 only partly tested).
- Once locked, the system cannot return except by reset (KEY0): intended; unlocking would need a change in part2.
- i5 (before the clock fix): key **A** always toggled the trick mode, but **B, C, D** toggled it only 1 time out of 2-4. Key codes read on LEDG: A = 1010, B = 1011, C = 1100, D = 1101 (correct when read alone). Hypothesis (to confirm): the columns have pull-up + capacitor on the board; a pressed key of column 3 holds the column low after the row is released in `kra0`, and at the sampling instant (5 us after the row change at 97.7 kHz) the column can still be read low = false key A. Fix applied: keypad clock q[8] -> q[10] (half period 20 us). **To re-test.**
- A `C` pressed in the middle of typing a code used to clear the digits (config-clear rule too wide): fixed with `clrnum`.

## 7. Open points / honest status

- Re-test on the board after the changes of this session: B/C/D must no longer toggle the trick mode; config mode (C, 4 digits, #); `*` and `C` from "Must be 4 digits".
- If the q[10] clock does not solve B/C/D, next option: a settling state in part1 after each row change (design change, would need new simulations).
- Part1 and the 3.4 remark ("check the keypad at a slow rate, rebounds <= 10 ms"): our fix is robust at any clock; with q[10] the look period is 41.9 ms. We could not know which fault the teacher meant in 3.1; ask the teacher if unsure (guide section 13).
- Extras 4 and 5 are not in the handout: present them as additional work, and keep i3 as the reference for the handout's improvement 3.
- LaTeX chapter for part1 exists; chapters for 3.2-3.5 still to write. Simulations still to do (section 5).

## 8. Git map

| Branch | Content |
|---|---|
| `main` | up to the 3.4/3.5 commits (`0e77b45`, `1d299f2`, `a835d67`) |
| `improvement-4-trick-lcd-message` | main + improvement 4 (i4) |
| `snapshot-improvement-5-wip` | everything up to i5, including a snapshot of the compile reports (`5914e5d`) and the latest fixes |

Commit messages mention when the board tests were pending.

## 9. Where the explanations already exist (reuse for the report text)

`presentation-guide.html`: big picture (1), files and revisions (2), keypad (3), part1 FSM and fault (4-6), part2 (7), 3.3 (8), 3.4 with clock, CLK_LOCK step by step, digit register and displays (9), improvements (10), decision log (11), Q&A (12), slow-rate remark (13), todo (14), lab finding on the keypad clock (15).
