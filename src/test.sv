class test extends uvm_test;
 `uvm_component_utils(test)
 function new(string name="test", uvm_component parent);
  super.new(name,parent);
 endfunction
 env env1;
 axi4lite_config m_cfg;
 function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  env1=env::type_id::create("env1",this);
  m_cfg=axi4lite_config::type_id::create("m_cfg");
  if(!(uvm_config_db#(axi4lite_config)::get(this,"","axi4lite_config",m_cfg)))
   `uvm_fatal(get_type_name(),"Didn't get the interface")
  m_cfg.input_agent_is_active=UVM_ACTIVE;
  m_cfg.output_agent_is_active=UVM_PASSIVE;
  uvm_config_db#(axi4lite_config)::set(this,"*","axi4lite_config",m_cfg);
 endfunction
 function void end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  uvm_top.print_topology();
 endfunction
endclass

class test1 extends test;
  
  `uvm_component_utils(test1)
  
  wr_seq w1;
  rd_seq r1;
  wrd_seq wrd1;
  err_seq e1;
  direct_seq d1;
  
  function new(string name="test1",uvm_component parent);
    super.new(name,parent);
  endfunction
  
 // function void build_phase(uvm_phase phase);
	//super.build_phase(phase);
  //endfunction
  
  task run_phase(uvm_phase phase);
    
    phase.raise_objection(this);
    
    w1=wr_seq::type_id::create("w1");
    r1=rd_seq::type_id::create("r1");
    wrd1=wrd_seq::type_id::create("wrd1");
    e1=err_seq::type_id::create("e1");
    d1=direct_seq::type_id::create("d1");
    
    w1.start(env1.inp_agt.seqr1);
    r1.start(env1.inp_agt.seqr1);
    wrd1.start(env1.inp_agt.seqr1);
    e1.start(env1.inp_agt.seqr1);
    d1.start(env1.inp_agt.seqr1);

	#50;  
    phase.drop_objection(this);
    
  endtask
  
endclass
