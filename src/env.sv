class env extends uvm_env;
 `uvm_component_utils(env)
 scoreboard sc;
 input_agent inp_agt;
 output_agent out_agt;
 subscriber sb;
 axi4lite_config m_cfg;
 function new(string name="env", uvm_component parent);
  super.new(name,parent);
 endfunction
 function void build_phase(uvm_phase phase);
  super.build_phase(phase);
 if(!(uvm_config_db#(axi4lite_config)::get(this,"","axi4lite_config",m_cfg)))
  `uvm_fatal(get_type_name(),"Didn't get the interface")
 uvm_config_db#(axi4lite_config)::set(null,"*","axi4lite_config",m_cfg);
 inp_agt=input_agent::type_id::create("inp_agt",this);
 out_agt=output_agent::type_id::create("out_agt",this);
 sc=scoreboard::type_id::create("sc",this);
 sb=subscriber::type_id::create("sb",this);
 endfunction
 function void connect_phase(uvm_phase phase);
  inp_agt.inp_mon.inp_monitor_port.connect(sc.inp_mon_fifo.analysis_export);
  out_agt.out_mon.out_monitor_port.connect(sc.out_mon_fifo.analysis_export);
  inp_agt.inp_mon.inp_monitor_port.connect(sb.analysis_export);
  out_agt.out_mon.out_monitor_port.connect(sb.analysis_export);
 endfunction
endclass


