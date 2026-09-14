`include "interface.sv"
`include "test_pkg.sv"
`include "design.sv"
module top();
import uvm_pkg::*;
    import test_pkg::*;
	bit clk;
   axi4lite_if DUV_IF(clk); 

  axi4_lite_slave DUV(.ACLK(DUV_IF.clk),.ARESETn(DUV_IF.ARESETn),.AWADDR(DUV_IF.AWADDR),.AWPROT(DUV_IF.AWPROT),.AWVALID(DUV_IF.AWVALID),.AWREADY(DUV_IF.AWREADY),.WDATA(DUV_IF.WDATA),.WSTRB(DUV_IF.WSTRB),.WVALID(DUV_IF.WVALID),.WREADY(DUV_IF.WREADY),.BRESP(DUV_IF.BRESP),.BVALID(DUV_IF.BVALID),.BREADY(DUV_IF.BREADY),.ARADDR(DUV_IF.ARADDR),.ARPROT(DUV_IF.ARPROT),.ARVALID(DUV_IF.ARVALID),.ARREADY(DUV_IF.ARREADY),.RDATA(DUV_IF.RDATA),.RRESP(DUV_IF.RRESP),.RVALID(DUV_IF.RVALID),.RREADY(DUV_IF.RREADY));
   
  axi4lite_config cfg;

 	initial
	begin
      //uvm_config_db#(virtual alu_if)::set(null,"*","alu_if",DUV_IF);
       cfg = axi4lite_config::type_id::create("cfg");

       cfg.vif = DUV_IF;

      uvm_config_db#(axi4lite_config)::set(
        null,
        "*",
        "axi4lite_config",
        cfg
      );
        $vcdplusfile("waveform.vpd");
        $vcdpluson;

      run_test("test1");
		
	end


	
	initial
	begin
		clk=1'b0;
		forever 
		   #5 clk=~clk;
	end
endmodule
