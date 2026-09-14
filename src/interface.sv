interface axi4lite_if(input bit clk);

    logic        ARESETn;
    logic [3:0]  WSTRB;
    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;
    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;
    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RREADY;
    logic [2:0]  AWPROT;
    logic [2:0]  ARPROT;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output ARESETn;
        output WSTRB, AWADDR, AWVALID, WDATA, WVALID,
               BREADY, ARADDR, ARVALID, RREADY, AWPROT, ARPROT;
        input  AWREADY, WREADY, BVALID, BRESP,
               ARREADY, RVALID, RDATA, RRESP;
    endclocking

    clocking inp_mon_cb @(posedge clk);
        default input #1step;
        input ARESETn;
        input WSTRB, AWADDR, AWVALID, WDATA, WVALID,
              BREADY, ARADDR, ARVALID, RREADY, AWPROT, ARPROT;
        input AWREADY, WREADY, ARREADY;
    endclocking

    clocking out_mon_cb @(posedge clk);
        default input #1step;
        input ARESETn;
        input WSTRB, AWADDR, AWVALID, WDATA, WVALID,
              BREADY, ARADDR, ARVALID, RREADY, AWPROT, ARPROT;
        input AWREADY, WREADY, BVALID, BRESP,
              ARREADY, RVALID, RDATA, RRESP;
    endclocking

    modport drv     (input clk, clocking drv_cb);
    modport inp_mon (input clk, clocking inp_mon_cb);
    modport out_mon (input clk, clocking out_mon_cb);

   property p1;
    @(posedge clk)
     disable iff(!ARESETn)
      (AWVALID && !AWREADY) |=> AWVALID;
   endproperty
   assert property (p1)
   else $error("AWVALID isn't stable until AWREADY occurs");

   property p2;
    @(posedge clk)
     disable iff(!ARESETn)
      (WVALID && !WREADY) |=> WVALID;
   endproperty
   assert property(p2)
   else $error("WVALID isn't stable until WREADY occurs");
    
endinterface
