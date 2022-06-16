
package test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class top extends uvm_test;  // 1.继承
    `uvm_component_utils(top)  // 2.注册
    function new(string name = "top", uvm_component parent = null);  // 3.new
      super.new(name, parent);
      `uvm_info("UVM_TOP", "SV TOP creating", UVM_LOW)
    endfunction
    task run_phase(uvm_phase phase);
      phase.raise_objection(this);  // 进入run phase后需要迅速挂起，不然经历时间后就会推出
      `uvm_info("UVM_TOP", "test is running", UVM_LOW)
      phase.drop_objection(this);
    endtask
  endclass

endpackage

module uvm_test_inst;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import test_pkg::*;


  initial begin
    `uvm_info("UVM_TOP", "test started", UVM_LOW)
    run_test("top");
    `uvm_info("UVM_TOP", "test finished", UVM_LOW)
  end

endmodule
