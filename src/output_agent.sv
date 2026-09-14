class output_agent extends uvm_agent;
  `uvm_component_utils(output_agent)

    output_monitor out_mon;
    axi4lite_config m_cfg;

   function new(string name="output_agent",uvm_component parent);
	super.new(name,parent);
   endfunction

  function void build_phase(uvm_phase phase);
	super.build_phase(phase);
    
  if(!uvm_config_db#(axi4lite_config)::get(this,"","axi4lite_config",m_cfg))
	`uvm_fatal(get_type_name(),"Output_agt Getting Failed")
    if(m_cfg.output_agent_is_active==UVM_PASSIVE)
    begin
    out_mon=output_monitor::type_id::create("out_mon",this); 
    end

  endfunction


 endclass

