class driver extends uvm_driver#(seq_item);
    `uvm_component_utils(driver)

    virtual axi4lite_if.drv vif;
    axi4lite_config m_cfg;
    seq_item data2duv;

    function new(string name="driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(axi4lite_config)::get(this, "", "axi4lite_config", m_cfg))
            `uvm_fatal(get_type_name(), "Input_Driver Getting Failed")
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vif = m_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
    vif.drv_cb.ARESETn <= 1'b0;
    vif.drv_cb.AWVALID <= 1'b0;
    vif.drv_cb.WVALID  <= 1'b0;
    vif.drv_cb.ARVALID <= 1'b0;
    vif.drv_cb.BREADY  <= 1'b0;
    vif.drv_cb.RREADY  <= 1'b0;

    repeat(3) @(vif.drv_cb);
    vif.drv_cb.ARESETn <= 1'b1;

    forever begin
        seq_item_port.get_next_item(req);
        drive(req);
        seq_item_port.item_done();
    end
endtask

    task drive(seq_item data2duv);
      
        if (data2duv.AWVALID) begin
            `uvm_info("INPUT_DRIVER",
                      $sformatf("[%s|WRITE] AWADDR=0x%0h | WDATA=0x%0h | WSTRB=0x%0h | AWPROT=0x%0h", data2duv.seq_id,
                          data2duv.AWADDR, data2duv.WDATA, data2duv.WSTRB, data2duv.AWPROT),
                UVM_LOW)
        end
        if (data2duv.ARVALID) begin
            `uvm_info("INPUT_DRIVER",
                      $sformatf("[%s|READ ] ARADDR=0x%0h | ARPROT=0x%0h",
                          data2duv.seq_id, data2duv.ARADDR, data2duv.ARPROT),
                UVM_LOW)
        end

        @(vif.drv_cb);
        vif.drv_cb.WSTRB   <= data2duv.WSTRB;
        vif.drv_cb.AWADDR  <= data2duv.AWADDR;
        vif.drv_cb.AWVALID <= data2duv.AWVALID;
        vif.drv_cb.WDATA   <= data2duv.WDATA;
        vif.drv_cb.WVALID  <= data2duv.WVALID;
        vif.drv_cb.BREADY  <= data2duv.BREADY;
        vif.drv_cb.ARADDR  <= data2duv.ARADDR;
        vif.drv_cb.ARVALID <= data2duv.ARVALID;
        vif.drv_cb.RREADY  <= data2duv.RREADY;
        vif.drv_cb.AWPROT  <= data2duv.AWPROT;
        vif.drv_cb.ARPROT  <= data2duv.ARPROT;
    endtask
endclass
