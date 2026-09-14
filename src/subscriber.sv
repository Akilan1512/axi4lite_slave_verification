class subscriber extends uvm_subscriber#(seq_item);
    `uvm_component_utils(subscriber)
    seq_item tr;
    // ---------- ADDRESS REGION COVERAGE ----------
    covergroup cg_addr_regions;
        cp_awaddr: coverpoint tr.AWADDR[7:0] {
            bins rw_region  = {[8'h00:8'h24], 8'h3C};
            bins ro_region  = {[8'h28:8'h30]};
            bins wo_region  = {[8'h34:8'h38]};
            bins invalid    = {[8'h40:8'hFF]};
        }
        cp_araddr: coverpoint tr.ARADDR[7:0] {
            bins rw_region  = {[8'h00:8'h24], 8'h3C};
            bins ro_region  = {[8'h28:8'h30]};
            bins wo_region  = {[8'h34:8'h38]};
            bins invalid    = {[8'h40:8'hFF]};
        }
    endgroup

    // ---------- WRITE STROBE COVERAGE ----------
    covergroup cg_wstrb;
        cp_wstrb: coverpoint tr.WSTRB {
            bins all_bytes     = {4'b1111};
            bins low_byte      = {4'b0001};
            bins high_byte     = {4'b1000};
            bins half_low      = {4'b0011};
            bins half_high     = {4'b1100};
            bins none          = {4'b0000};   // ← often missed!
            bins others[]      = default;
        }
    endgroup

    // ---------- RESPONSE COVERAGE ----------
    covergroup cg_bresp;
        cp_bresp: coverpoint tr.BRESP {
            bins okay   = {2'b00};
        //    bins exokay = {2'b01};   may be unused
            bins slverr = {2'b10};
            bins decerr = {2'b11};
        }
    endgroup

    covergroup cg_rresp;
        cp_rresp: coverpoint tr.RRESP {
            bins okay   = {2'b00};
         //   bins exokay = {2'b01};
            bins slverr = {2'b10};
            bins decerr = {2'b11};
        }
    endgroup

    // ---------- ALIGNMENT ----------
    covergroup cg_alignment;
        cp_aw_align: coverpoint tr.AWADDR[1:0] {
            bins aligned   = {2'b00};
            bins unaligned = {2'b01, 2'b10, 2'b11};
        }
        cp_ar_align: coverpoint tr.ARADDR[1:0] {
            bins aligned   = {2'b00};
            bins unaligned = {2'b01, 2'b10, 2'b11};
        }
    endgroup

    // ---------- TRANSACTION TYPE ----------
    covergroup cg_txn_type;
        cp_kind: coverpoint tr.kind {
            bins read  = {seq_item::READ};
            bins write = {seq_item::WRITE};
        }
    endgroup

    // ---------- READ/WRITE CONCURRENCY ----------
    covergroup cg_concurrent;
        cp_both_valid: coverpoint {tr.AWVALID, tr.ARVALID} {
            bins write_only = {2'b10};
            bins read_only  = {2'b01};
            bins both       = {2'b11};
            bins neither    = {2'b00};
        }
    endgroup

    // ---------- WORD ADDRESS COVERAGE ----------
    // Ensure every word in the 16-word RAM is accessed
    covergroup cg_word_index;
        cp_word: coverpoint tr.AWADDR[5:2] {
            bins w[] = {[0:15]};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_addr_regions = new;
        cg_wstrb        = new;
        cg_bresp        = new;
        cg_rresp        = new;
        cg_alignment    = new;
        cg_txn_type     = new;
        cg_concurrent   = new;
        cg_word_index   = new;
    endfunction

   function void write(seq_item t);
    tr = t;
    cg_txn_type.sample();

    if (tr.kind == seq_item::WRITE) begin
        cg_addr_regions.sample();
        cg_wstrb.sample();
        cg_alignment.sample();
        cg_word_index.sample();
        if (tr.BVALID === 1'b1)
            cg_bresp.sample();
    end
    else if (tr.kind == seq_item::READ) begin
        cg_addr_regions.sample();
        cg_alignment.sample();
        if (tr.RVALID === 1'b1)
            cg_rresp.sample();
    end

    cg_concurrent.sample();
endfunction
endclass
