class input_monitor extends uvm_monitor;
    `uvm_component_utils(input_monitor)

    uvm_analysis_port#(seq_item) inp_monitor_port;
    virtual axi4lite_if.inp_mon vif;
    axi4lite_config m_cfg;

    function new(string name="input_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(axi4lite_config)::get(this, "", "axi4lite_config", m_cfg))
            `uvm_fatal(get_type_name(), "Couldn't get the interface")
        inp_monitor_port = new("inp_monitor_port", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vif = m_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
      `uvm_info("INPUT_MONITOR", ">>> run_phase started", UVM_NONE)
        fork
            collect_write();
            collect_read();
        join
    endtask

    // -------- WRITE MONITOR (AW + W channels) --------
    virtual task collect_write();
        seq_item tr;
       `uvm_info("INPUT_MONITOR", ">>> collect_write entered", UVM_NONE)
        // Wait until reset is released
        wait (vif.inp_mon_cb.ARESETn === 1'b1);
      `uvm_info("INPUT_MONITOR", ">>> collect_write: reset released", UVM_NONE)
        forever begin
            // Wait for AW handshake
            @(vif.inp_mon_cb);
          `uvm_info("INPUT_MONITOR",
            $sformatf(">>> AWVALID=%b AWREADY=%b WVALID=%b WREADY=%b",
                      vif.inp_mon_cb.AWVALID, vif.inp_mon_cb.AWREADY,
                      vif.inp_mon_cb.WVALID,  vif.inp_mon_cb.WREADY),
            UVM_NONE)
            while (!(vif.inp_mon_cb.AWVALID === 1'b1 &&
                     vif.inp_mon_cb.AWREADY === 1'b1))
                @(vif.inp_mon_cb);
          `uvm_info("INPUT_MONITOR", ">>> AW handshake detected", UVM_NONE)

            tr = seq_item::type_id::create("wr_tr");
            tr.kind    = seq_item::WRITE;
            tr.AWADDR  = vif.inp_mon_cb.AWADDR;
            tr.AWPROT  = vif.inp_mon_cb.AWPROT;
            tr.ARESETn = vif.inp_mon_cb.ARESETn;

            // Wait for W handshake (may occur before, after, or with AW)
            @(vif.inp_mon_cb);
            while (!(vif.inp_mon_cb.WVALID === 1'b1 &&
                     vif.inp_mon_cb.WREADY === 1'b1))
                @(vif.inp_mon_cb);

            tr.WDATA = vif.inp_mon_cb.WDATA;
            tr.WSTRB = vif.inp_mon_cb.WSTRB;

            `uvm_info("INPUT_MONITOR",
                $sformatf("[WRITE] AWADDR=0x%0h WDATA=0x%0h WSTRB=0x%0h AWPROT=0x%0h",
                          tr.AWADDR, tr.WDATA, tr.WSTRB, tr.AWPROT),
                UVM_LOW)

            inp_monitor_port.write(tr);
        end
    endtask

    // -------- READ MONITOR (AR channel) --------
    virtual task collect_read();
        seq_item tr;
      `uvm_info("INPUT_MONITOR", ">>> collect_read entered", UVM_NONE)
        // Wait until reset is released
        wait (vif.inp_mon_cb.ARESETn === 1'b1);
       `uvm_info("INPUT_MONITOR", ">>> collect_read: reset released", UVM_NONE)
        forever begin
            @(vif.inp_mon_cb);
            while (!(vif.inp_mon_cb.ARVALID === 1'b1 &&
                     vif.inp_mon_cb.ARREADY === 1'b1))
                @(vif.inp_mon_cb);
           `uvm_info("INPUT_MONITOR", ">>> AR handshake detected", UVM_NONE)

            tr = seq_item::type_id::create("rd_tr");
            tr.kind    = seq_item::READ;
            tr.ARADDR  = vif.inp_mon_cb.ARADDR;
            tr.ARPROT  = vif.inp_mon_cb.ARPROT;
            tr.ARESETn = vif.inp_mon_cb.ARESETn;

            `uvm_info("INPUT_MONITOR",
                $sformatf("[READ ] ARADDR=0x%0h ARPROT=0x%0h",
                          tr.ARADDR, tr.ARPROT),
                UVM_LOW)

            inp_monitor_port.write(tr);
        end
    endtask

endclass
