class output_monitor extends uvm_monitor;
    `uvm_component_utils(output_monitor)

    uvm_analysis_port#(seq_item) out_monitor_port;
    virtual axi4lite_if.out_mon vif;
    axi4lite_config m_cfg;

    function new(string name="output_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(axi4lite_config)::get(this, "", "axi4lite_config", m_cfg))
            `uvm_fatal(get_type_name(), "Output_Monitor Getting Failed")
        out_monitor_port = new("out_monitor_port", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vif = m_cfg.vif;
    endfunction

    task run_phase(uvm_phase phase);
        fork
            collect_bresp();
            collect_rresp();
        join
    endtask

    // -------- B CHANNEL (Write Response) --------
    virtual task collect_bresp();
        seq_item tr;
        // Wait until reset is released
        wait (vif.out_mon_cb.ARESETn === 1'b1);
        forever begin
            @(vif.out_mon_cb);
            while (!(vif.out_mon_cb.BVALID === 1'b1 &&
                     vif.out_mon_cb.BREADY === 1'b1))
                @(vif.out_mon_cb);

            tr = seq_item::type_id::create("b_tr");
            tr.kind    = seq_item::WRITE;
            tr.BRESP   = vif.out_mon_cb.BRESP;
            tr.BVALID  = vif.out_mon_cb.BVALID;
            tr.BREADY  = vif.out_mon_cb.BREADY;
            tr.ARESETn = vif.out_mon_cb.ARESETn;

            `uvm_info("OUTPUT_MONITOR",
                $sformatf("[BRESP] BRESP=0x%0h", tr.BRESP),
                UVM_LOW)

            out_monitor_port.write(tr);
        end
    endtask

    // -------- R CHANNEL (Read Response) --------
    virtual task collect_rresp();
        seq_item tr;
        // Wait until reset is released
        wait (vif.out_mon_cb.ARESETn === 1'b1);
        forever begin
            @(vif.out_mon_cb);
            while (!(vif.out_mon_cb.RVALID === 1'b1 &&
                     vif.out_mon_cb.RREADY === 1'b1))
                @(vif.out_mon_cb);

            tr = seq_item::type_id::create("r_tr");
            tr.kind    = seq_item::READ;
            tr.RDATA   = vif.out_mon_cb.RDATA;
            tr.RRESP   = vif.out_mon_cb.RRESP;
            tr.RVALID  = vif.out_mon_cb.RVALID;
            tr.RREADY  = vif.out_mon_cb.RREADY;
            tr.ARESETn = vif.out_mon_cb.ARESETn;

            `uvm_info("OUTPUT_MONITOR",
                $sformatf("[RDATA] RDATA=0x%0h | RRESP=0x%0h",
                          tr.RDATA, tr.RRESP),
                UVM_LOW)

            out_monitor_port.write(tr);
        end
    endtask

endclass
