//---------------------------------------------------------
// WRITE-ONLY
//---------------------------------------------------------
class wr_seq extends uvm_sequence#(seq_item);
    `uvm_object_utils(wr_seq)
    function new(string name="wr_seq"); super.new(name); endfunction

    task body();
        repeat(50) begin
            req = seq_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                AWADDR inside {[32'h00:32'h3C]};
                AWADDR[1:0] == 2'b00;
                AWVALID     == 1'b1;
                WVALID      == 1'b1;
                BREADY      == 1'b1;
                ARVALID     == 1'b0;
                RREADY      == 1'b0;
            });
            req.seq_id = "w1";
            req.kind   = seq_item::WRITE;
            finish_item(req);
        end
    endtask
endclass

//---------------------------------------------------------
// READ-ONLY
//---------------------------------------------------------
class rd_seq extends uvm_sequence#(seq_item);
    `uvm_object_utils(rd_seq)
    function new(string name="rd_seq"); super.new(name); endfunction

    task body();
        repeat(50) begin
            req = seq_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                ARADDR inside {[32'h00:32'h3C]};
                ARADDR[1:0] == 2'b00;
                ARVALID     == 1'b1;
                RREADY      == 1'b1;
                AWVALID     == 1'b0;
                WVALID      == 1'b0;
                BREADY      == 1'b0;
            });
            req.seq_id = "r1";
            req.kind   = seq_item::READ;
            finish_item(req);
        end
    endtask
endclass

//---------------------------------------------------------
// WRITE + READ
//---------------------------------------------------------
class wrd_seq extends uvm_sequence#(seq_item);
    `uvm_object_utils(wrd_seq)
    function new(string name="wrd_seq"); super.new(name); endfunction

    task body();
        repeat(100) begin
            req = seq_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                AWADDR inside {[32'h00:32'h3C]};
                AWADDR[1:0] == 2'b00;
                ARADDR inside {[32'h00:32'h3C]};
                ARADDR[1:0] == 2'b00;
                AWVALID == 1'b1;
                WVALID  == 1'b1;
                BREADY  == 1'b1;
                ARVALID == 1'b1;
                RREADY  == 1'b1;
            });
            req.seq_id = "wrd1";
            finish_item(req);
        end
    endtask
endclass

//---------------------------------------------------------
// DIRECT (write-read same address)
//---------------------------------------------------------
class direct_seq extends uvm_sequence#(seq_item);
    `uvm_object_utils(direct_seq)
    function new(string name="direct_seq"); super.new(name); endfunction

    task body();
        repeat(5) begin
            req = seq_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                AWADDR inside {[32'h00:32'h24], 32'h3C};
                AWADDR[1:0] == 2'b00;
                AWVALID     == 1'b1;
                WVALID      == 1'b1;
                BREADY      == 1'b1;

                ARADDR == AWADDR;
                ARVALID     == 1'b1;
                RREADY      == 1'b1;
            });
            req.seq_id = "d1";
            finish_item(req);
        end
    endtask
endclass

//---------------------------------------------------------
// ERROR CASES
//---------------------------------------------------------
class err_seq extends uvm_sequence#(seq_item);
    `uvm_object_utils(err_seq)
    function new(string name="err_seq"); super.new(name); endfunction

    task body();
        // ---- Case 1: unaligned address (SLVERR) ----
        req = seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            AWADDR inside {[32'h00:32'h3C]};
            AWADDR[1:0] inside {2'b01, 2'b10, 2'b11};
            AWVALID     == 1'b1;
            WVALID      == 1'b1;
            BREADY      == 1'b1;
            ARVALID     == 1'b0;
            RREADY      == 1'b0;
        });
        req.seq_id = "e1";
        req.kind   = seq_item::WRITE;
        finish_item(req);

        // ---- Case 2: address out of range (DECERR) ----
        req = seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            AWADDR > 32'h3F;
            AWVALID     == 1'b1;
            WVALID      == 1'b1;
            BREADY      == 1'b1;
            ARVALID     == 1'b0;
            RREADY      == 1'b0;
        });
        req.seq_id = "e1";
        req.kind   = seq_item::WRITE;
        finish_item(req);

        // ---- Case 3: write to RO region (SLVERR) ----
        req = seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            AWADDR inside {[32'h28:32'h30]};
            AWADDR[1:0] == 2'b00;
            AWVALID     == 1'b1;
            WVALID      == 1'b1;
            BREADY      == 1'b1;
            ARVALID     == 1'b0;
            RREADY      == 1'b0;
        });
        req.seq_id = "e1";
        req.kind   = seq_item::WRITE;
        finish_item(req);

        // ---- Case 4: read from WO region (SLVERR) ----
        req = seq_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            ARADDR inside {[32'h34:32'h38]};
            ARADDR[1:0] == 2'b00;
            ARVALID     == 1'b1;
            RREADY      == 1'b1;
            AWVALID     == 1'b0;
            WVALID      == 1'b0;
            BREADY      == 1'b0;
        });
        req.seq_id = "e1";
        req.kind   = seq_item::READ;
        finish_item(req);
    endtask
endclass
