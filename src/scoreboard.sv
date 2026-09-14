class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_tlm_analysis_fifo#(seq_item) inp_mon_fifo;
    uvm_tlm_analysis_fifo#(seq_item) out_mon_fifo;

    // Reference memory (16 words = 64 bytes)
    logic [31:0] mem [16];

    // Pending write tracking
    bit [31:0] pending_addr;
    bit [31:0] pending_data;
    bit [3:0]  pending_strb;

    // Pending read queue
    seq_item   exp_read_q[$];

    // Statistics
    int unsigned num_writes;
    int unsigned num_reads;
    int unsigned num_pass;
    int unsigned num_fail;

    function new(string name="scoreboard", uvm_component parent);
        super.new(name, parent);
        inp_mon_fifo = new("inp_mon_fifo", this);
        out_mon_fifo = new("out_mon_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);
        fork
            process_inputs();
            process_outputs();
        join
    endtask

    // ---------------- INPUT SIDE ----------------
    task process_inputs();
        seq_item tr;
        seq_item exp;
        forever begin
            inp_mon_fifo.get(tr);

            if (tr.kind == seq_item::WRITE) begin
                pending_addr = tr.AWADDR;
                pending_data = tr.WDATA;
                pending_strb = tr.WSTRB;
            end
            else if (tr.kind == seq_item::READ) begin
                exp = seq_item::type_id::create("exp_rd");
                exp.ARADDR = tr.ARADDR;
                exp.kind   = seq_item::READ;
                compute_expected_read(exp);
                exp_read_q.push_back(exp);
            end
        end
    endtask

    // ---------------- OUTPUT SIDE ----------------
    task process_outputs();
        seq_item tr;
        seq_item exp;
        forever begin
            out_mon_fifo.get(tr);

            if (tr.kind == seq_item::WRITE) begin
                num_writes++;
                exp = seq_item::type_id::create("exp_wr");
                compute_expected_write(exp);
                compare_bresp(exp, tr);
            end
            else if (tr.kind == seq_item::READ) begin
                num_reads++;
                if (exp_read_q.size() == 0) begin
                    `uvm_error("SCOREBOARD",
                        $sformatf("Read response received with no pending request! RRESP=0x%0h",
                                  tr.RRESP))
                end
                else begin
                    exp = exp_read_q.pop_front();
                    compare_rresp(exp, tr);
                end
            end
        end
    endtask

    // ---------------- REFERENCE MODEL ----------------
    // Spec rules:
    //   - Address out of [0x00:0x3F]        -> DECERR (2'b11)
    //   - Unaligned (addr[1:0] != 0)        -> SLVERR (2'b10)
    //   - RO region (0x28-0x30) write       -> SLVERR (2'b10)
    //   - WO region (0x34-0x38) read        -> SLVERR (2'b10)
    //   - Otherwise                         -> OKAY (2'b00)

    function void compute_expected_write(seq_item exp);
        // 1. Out of range?
        if (pending_addr > 32'h3F) begin
            exp.BRESP = 2'b11;                     // DECERR
            return;
        end

        // 2. Unaligned?
        if (pending_addr[1:0] != 2'b00) begin
            exp.BRESP = 2'b10;                     // SLVERR
            return;
        end

        // 3. Write to read-only region?
        if (pending_addr[7:0] inside {[8'h28:8'h30]}) begin
            exp.BRESP = 2'b10;                     // SLVERR
            return;
        end

        // 4. Valid write
        exp.BRESP = 2'b00;                          // OKAY
        if (pending_strb[0]) mem[pending_addr[5:2]][7:0]   = pending_data[7:0];
        if (pending_strb[1]) mem[pending_addr[5:2]][15:8]  = pending_data[15:8];
        if (pending_strb[2]) mem[pending_addr[5:2]][23:16] = pending_data[23:16];
        if (pending_strb[3]) mem[pending_addr[5:2]][31:24] = pending_data[31:24];
    endfunction

    function void compute_expected_read(seq_item exp);
        // 1. Out of range?
        if (exp.ARADDR > 32'h3F) begin
            exp.RRESP = 2'b11;                     // DECERR
            exp.RDATA = 32'h0;
            return;
        end

        // 2. Unaligned?
        if (exp.ARADDR[1:0] != 2'b00) begin
            exp.RRESP = 2'b10;                     // SLVERR
            exp.RDATA = 32'h0;
            return;
        end

        // 3. Read from write-only region?
        if (exp.ARADDR[7:0] inside {[8'h34:8'h38]}) begin
            exp.RRESP = 2'b10;                     // SLVERR
            exp.RDATA = 32'h0;
            return;
        end

        // 4. Valid read
        exp.RRESP = 2'b00;                          // OKAY
        exp.RDATA = mem[exp.ARADDR[5:2]];
    endfunction

    // ---------------- COMPARES ----------------
    function void compare_bresp(seq_item exp, seq_item act);
        if (exp.BRESP !== act.BRESP) begin
            num_fail++;
            `uvm_error("SCOREBOARD",
                $sformatf("BRESP MISMATCH: exp=0x%0h act=0x%0h",
                          exp.BRESP, act.BRESP))
        end
        else begin
            num_pass++;
            `uvm_info("SCOREBOARD",
                $sformatf("BRESP OK (0x%0h)", act.BRESP), UVM_HIGH)
        end
    endfunction

    function void compare_rresp(seq_item exp, seq_item act);
        if (exp.RDATA !== act.RDATA || exp.RRESP !== act.RRESP) begin
            num_fail++;
            `uvm_error("SCOREBOARD",
                $sformatf("RDATA MISMATCH: exp RDATA=0x%0h RRESP=0x%0h | act RDATA=0x%0h RRESP=0x%0h",
                          exp.RDATA, exp.RRESP, act.RDATA, act.RRESP))
        end
        else begin
            num_pass++;
            `uvm_info("SCOREBOARD",
                $sformatf("RDATA OK (0x%0h, RRESP=0x%0h)", act.RDATA, act.RRESP),
                UVM_HIGH)
        end
    endfunction

    // ---------------- REPORT ----------------
    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", "======================================", UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Writes checked : %0d", num_writes), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Reads checked  : %0d", num_reads),  UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Passes         : %0d", num_pass),   UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("Failures       : %0d", num_fail),   UVM_LOW)
        if (num_writes + num_reads == 0)
            `uvm_error("SCOREBOARD", "*** TEST FAILED: no transactions checked ***")
        else if (num_fail == 0)
            `uvm_info("SCOREBOARD", "*** TEST PASSED ***", UVM_LOW)
        else
            `uvm_error("SCOREBOARD", "*** TEST FAILED ***")
        `uvm_info("SCOREBOARD", "======================================", UVM_LOW)
    endfunction

endclass
