class seq_item extends uvm_sequence_item;
    `uvm_object_utils(seq_item)

    typedef enum { READ, WRITE, UNKNOWN } kind_e;

    string seq_id = "unknown";

    kind_e kind = UNKNOWN;

    rand bit ARESETn;
    rand bit [3:0]  WSTRB;
    rand bit [31:0] AWADDR;
    rand bit        AWVALID;
    rand bit [31:0] WDATA;
    rand bit        WVALID;
    rand bit        BREADY;
    rand bit [31:0] ARADDR;
    rand bit        ARVALID;
    rand bit        RREADY;
    rand bit [2:0]  AWPROT;
    rand bit [2:0]  ARPROT;

    logic        AWREADY, WREADY, BVALID, ARREADY, RVALID;
    logic [1:0]  BRESP;
    logic [1:0]  RRESP;
    logic [31:0] RDATA;

    function new(string name="seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        if (kind == WRITE)
            return $sformatf("[%s|WRITE] AWADDR=0x%0h WDATA=0x%0h WSTRB=0x%0h AWPROT=0x%0h",
                             seq_id, AWADDR, WDATA, WSTRB, AWPROT);
        else if (kind == READ)
            return $sformatf("[%s|READ ] ARADDR=0x%0h ARPROT=0x%0h",
                             seq_id, ARADDR, ARPROT);
        else
            return $sformatf("[%s|?    ] raw item", seq_id);
    endfunction

endclass
