class input_agent extends uvm_agent;
 `uvm_component_utils(input_agent)
 function new(string name="input_agent", uvm_component parent);
  super.new(name,parent);
 endfunction
 input_monitor inp_mon;
 driver drv;
 seqr seqr1;
 axi4lite_config m_cfg;
 function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(axi4lite_config)::get(this,"","axi4lite_config",m_cfg))
   `uvm_fatal(get_type_name(),"Couldn't get the interface")
  
   inp_mon=input_monitor::type_id::create("inp_mon",this);

    if(m_cfg.input_agent_is_active==UVM_ACTIVE)
    begin
    drv=driver::type_id::create("drv",this);
    seqr1=seqr::type_id::create("seqr1",this);
    end

  endfunction

 function void connect_phase(uvm_phase phase);
	if(m_cfg.input_agent_is_active==UVM_ACTIVE)
	    begin
		drv.seq_item_port.connect(seqr1.seq_item_export);
	    end
 endfunction

 endclass
