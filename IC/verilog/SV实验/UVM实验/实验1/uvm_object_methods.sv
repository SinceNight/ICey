
package object_methods_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  typedef enum {WRITE, READ, IDLE} op_t;  

  class trans extends uvm_object;
    bit[31:0] addr;
    bit[31:0] data;
    op_t op;
    string name;
    `uvm_object_utils_begin(trans)   // 注册的时候同时对trans中参与的变量进行自动化声明
      //TODO-2.1 
      //Apply field automation macros such as
        `uvm_field_int(ARG, UVM_ALL_ON)
        `uvm_field_enum(T, ARG, UVM_ALL_ON)
        `uvm_field_string(ARG, UVM_ALL_ON)
      //to register all of member variables
    `uvm_object_utils_end
    function new(string name = "trans");
      super.new(name);
      `uvm_info("CREATE", $sformatf("trans type [%s] created", name), UVM_LOW)
    endfunction
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      //TODO-2.4
      //Please just try to compare all of properties of the two properties
      //and give detailed comparison messages
    endfunction
  endclass


  class object_methods_test extends uvm_test;
    `uvm_component_utils(object_methods_test)
    function new(string name = "object_methods_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
    endfunction
    task run_phase(uvm_phase phase);
      trans t1, t2;
      bit is_equal;
      phase.raise_objection(this);
      t1 = trans::type_id::create("t1");
      t1.data = 'h1FF;
      t1.addr = 'hF100;
      t1.op = WRITE;
      t1.name = "t1";
      t2 = trans::type_id::create("t2");
      t2.data = 'h2FF;
      t2.addr = 'hF200;
      t2.op = WRITE;
      t2.name = "t2";
      is_equal = t1.compare(t2);
      uvm_default_comparer.show_max = 10;
      is_equal = t1.compare(t2);   // compare自动回调do_compare函数
      //TODO-2.2 
      //Use function bit compare (uvm_object rhs, uvm_comparer comparer=null)
      //to compare t1 and t2, and check the message output
      
      //TODO-2.3
      //uvm_default_comparer (uvm_comparer type) is the default UVM global comparer, 
      //you would set its property like 'show_max' to ask more of the comparison result
      //Please set this property and do the compare again

        
      `uvm_info("COPY", "Before uvm_object copy() taken", UVM_LOW)
      //TODO-2.5
      //Use uvm_object::print() method to display all of fields before copy()
      `uvm_info("COPY", "Before uvm_object copy() taken", UVM_LOW)   
      t1.print();
      t2.print();
      `uvm_info("COPY", "After uvm_object t2 is copied to t1", UVM_LOW)
      t1.copy(t2);  // t1拷贝t2，之后输出
      t1.print();
      t2.print();
      `uvm_info("CMP", "Compare t1 and t2", UVM_LOW)
      
      `uvm_info("COPY", "After uvm_object t2 is copied to t1", UVM_LOW)
      //TODO-2.6
      //Call uvm_object::copy(uvm_object rhs) to copy t2 to t1
      //and use print() and compare() to follow steps above again for them
      is_equal = t1.compare(t2);
      if(!is_equal)
        `uvm_warning("CMPERR", "t1 is not equal to t2")  // 拷贝完之后再次进行比较。
      else
        `uvm_info("CMPERR", "t1 is equal to t2", UVM_LOW)     
   
      phase.drop_objection(this);
    endtask
  endclass
  
endpackage

module object_methods;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import object_methods_pkg::*;

  initial begin
    run_test(""); // empty test name
  end

endmodule
