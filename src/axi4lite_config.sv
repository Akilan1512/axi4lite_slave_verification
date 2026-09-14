`include "uvm_macros.svh"
import uvm_pkg::*;
class axi4lite_config extends uvm_object;
   `uvm_object_utils(axi4lite_config)
  //virtual
  virtual axi4lite_if vif;

  uvm_active_passive_enum input_agent_is_active;
  uvm_active_passive_enum output_agent_is_active;

  
  function new(string name="axi4lite_config");
	super.new(name);
  endfunction

endclass
