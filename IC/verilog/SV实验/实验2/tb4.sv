`timescale 1ns/1ps

interface chnl_intf(input clk, input rstn);
  logic [31:0] ch_data;
  logic        ch_valid;
  logic        ch_ready;
  logic [ 5:0] ch_margin;
  clocking drv_ck @(posedge clk);
    default input #1ns output #1ns;
    output ch_data, ch_valid;
    input ch_ready, ch_margin;
  endclocking
endinterface

package chnl_pkg;  // 定义用得上的变量
  class chnl_trans;
    int data;
    int id;
    int num;
  endclass: chnl_trans
  
  class chnl_initiator;
    local string name;
    local int idle_cycles;
    local virtual chnl_intf intf;
  
    function new(string name = "chnl_initiator");
      this.name = name;  // 给实例创建名字
      this.idle_cycles = 1;
    endfunction
  
    function void set_idle_cycles(int n);
      this.idle_cycles = n;
    endfunction
  
    function void set_name(string s);
      this.name = s;
    endfunction
  
    function void set_interface(virtual chnl_intf intf);
      if(intf == null)
        $error("interface handle is NULL, please check if target interface has been intantiated");
      else
        this.intf = intf;
    endfunction
  
    task chnl_write(input chnl_trans t);  // 由15行定义
      @(posedge intf.clk);
      // USER TODO 1.1
      // Please use the clocking drv_ck of chnl_intf to drive data
      intf.ch_valid <= 1;
      intf.ch_data <= t.data;
      wait(intf.ch_ready === 'b1);
      $display("%t channel initiator [%s] sent data %x", $time, name, t.data);
      // USER TODO 1.2
      // Apply variable idle_cycles and decide how many idle cycles to be
      // inserted between two sequential data
      chnl_idle();
    endtask
    
    task chnl_idle();
      @(posedge intf.clk);
      // USER TODO 1.1
      // Please use the clocking drv_ck of chnl_intf to drive data
      intf.ch_valid <= 0;
      intf.ch_data <= 0;
    endtask
  endclass: chnl_initiator
  
  class chnl_generator;
    chnl_trans trans[$];
    int num;
    int id;
    function new(int n);
      this.id = n;
      this.num = 0;
    endfunction
    function chnl_trans get_trans();  // // 因为generator和chnl_trans是不同类，因此调用需要给chnl_trans授予句柄   和47行类似，给类赋予方法
      chnl_trans t = new();  // 给trans创建实例，这个方法即使没有get_trans的指针也能执行
      t.data = 'h00C0_0000 + (this.id<<16) + this.num;   // 对创建的实例进行赋值
      t.id = this.id; 
      t.num = this.num;
      this.num++;
      this.trans.push_back(t);
      return t;
    endfunction
  endclass: chnl_generator

  class chnl_agent;  // 将一组generator和initiator放在了一起，共需3组agent
    chnl_generator gen;   // 创建句柄
    chnl_initiator init;
    local int ntrans;
    local virtual chnl_intf vif;
    function new(string name = "chnl_agent", int id = 0, int ntrans = 1); // (agent名字，对应id，运行次数)  new函数用于其他类调用，如116行。
      this.gen = new(id); //调用generator的new创建实例
      this.init = new(name); //调用initiator的new创建实例
      this.ntrans = ntrans;
    endfunction
    function void set_ntrans(int n);
      this.ntrans = n;
    endfunction
    function void set_interface(virtual chnl_intf vif);
      this.vif = vif;
      init.set_interface(vif);
    endfunction
    task run();  // 通过函数发送激励，类似实验3的basic_test
      repeat(this.ntrans) this.init.chnl_write(this.gen.get_trans());  // 发送数据，agent控制数据产生数量
    endtask 
  endclass: chnl_agent

  class chnl_root_test;  // root是agent上一层模块，他要让anget跑起来
    chnl_agent agent[3];  // 对chnl_agent声明句柄
    protected string name;
    function new(int ntrans = 100, string name = "chnl_root_test");  //此处如果调用new函数ntrans=100会覆盖ntrans=1, 重新赋值。
      foreach(agent[i]) begin
        this.agent[i] = new($sformatf("chnl_agent%0d",i), i, ntrans);  // 注意，如果此处的ntrans和i有赋值，将会以此处的为主！以最后一次赋值为主
      end
      this.name = name;
      $display("%s instantiate objects", this.name);
    endfunction
    task run();
      $display("%s started testing DUT", this.name);
      fork
        agent[0].run();
        agent[1].run();
        agent[2].run();
      join
      $display("%s finished testing DUT", this.name);
    endtask
    function void set_interface(virtual chnl_intf ch0_vif, virtual chnl_intf ch1_vif, virtual chnl_intf ch2_vif);
      agent[0].set_interface(ch0_vif);
      agent[1].set_interface(ch1_vif);
      agent[2].set_interface(ch2_vif);
    endfunction
  endclass

  class chnl_basic_test extends chnl_root_test;                                      //chnl_basic_test 平行 chnl_root_test > agent > initiator+generator
    function new(int ntrans = 200, string name = "chnl_basic_test"); // 存在两个ntrans，这里没有对root_test做例化，需要哪个就例化哪个！！
      super.new(ntrans, name);  // 继承agnet中的new
      foreach(agent[i]) begin    // 这里没有出现新的agent，因此调用agent不需要super！！！！
        this.agent[i].init.set_idle_cycles($urandom_range(1, 3));  // 随机设置cycles, 在实验3中，这一步被放入了generator中，因此可以省去。
      end
      $display("%s configured objects", this.name);
    endfunction
  endclass: chnl_basic_test   // 通过继承的方式，省去了代码重复书写的过程。

  class chnl_burst_test extends chnl_root_test;                            // 这3个test层次结构一致，比如都存在run。只是发送的激励不一样。
    //USER TODO
    function new(int ntrans = 500, string name = "chnl_burst_test");
    super.new(ntrans,name)
    foreach(angent[i]) begin
      this.agent[i].init.set_idle_cycles(0);
    end
     $display("%s configured objects", this.name);
  endfunction
  endclass: chnl_burst_test

 
  class chnl_fifo_full_test extends chnl_root_test;
    // USER TODO
    function new(int ntrans = 1_000_000, string name = "chnl_fifo_full_test");
      super.new(ntrans, name);
      foreach(agent[i]) begin
        this.agent[i].init.set_idle_cycles(0);
      end
      $display("%s configured objects", this.name);
    endfunction
    task fifo_full_test
    fork
      forever agent[0].run();
      forever agent[1].run();
      forever agent[2].run();
    join_none
  endclass: chnl_fifo_full_test

endpackage: chnl_pkg  // 所用的class通过package打包


module tb4;
  logic         clk;
  logic         rstn;
  logic [31:0]  mcdt_data;
  logic         mcdt_val;
  logic [ 1:0]  mcdt_id;
  
  mcdt dut(
     .clk_i       (clk                )
    ,.rstn_i      (rstn               )
    ,.ch0_data_i  (chnl0_if.ch_data   )
    ,.ch0_valid_i (chnl0_if.ch_valid  )
    ,.ch0_ready_o (chnl0_if.ch_ready  )
    ,.ch0_margin_o(chnl0_if.ch_margin )
    ,.ch1_data_i  (chnl1_if.ch_data   )
    ,.ch1_valid_i (chnl1_if.ch_valid  )
    ,.ch1_ready_o (chnl1_if.ch_ready  )
    ,.ch1_margin_o(chnl1_if.ch_margin )
    ,.ch2_data_i  (chnl2_if.ch_data   )
    ,.ch2_valid_i (chnl2_if.ch_valid  )
    ,.ch2_ready_o (chnl2_if.ch_ready  )
    ,.ch2_margin_o(chnl2_if.ch_margin )
    ,.mcdt_data_o (mcdt_data          )
    ,.mcdt_val_o  (mcdt_val           )
    ,.mcdt_id_o   (mcdt_id            )
  );
  
  // clock generation
  initial begin 
    clk <= 0;
    forever begin
      #5 clk <= !clk;
    end
  end
  
  // reset trigger
  initial begin 
    #10 rstn <= 0;
    repeat(10) @(posedge clk);
    rstn <= 1;
  end

  // USER TODO 4.1
  // import defined class from chnl_pkg
  import chnl_pkg::*; //导入package

  chnl_intf chnl0_if(.*); // 接口例化
  chnl_intf chnl1_if(.*);
  chnl_intf chnl2_if(.*);

  chnl_basic_test basic_test;  // 对三个test做实例，不实例无法运行，而且对应的每个类也需要实例，比如root_test里面实例化agent
  chnl_burst_test burst_test;
  chnl_fifo_full_test fifo_full_test;

  initial begin //           

    // USER TODO 4.3
    // Instantiate the three test environment

    // USER TODO 4.4
    // assign the interface handle to each chnl_initiator objects   // 设置接口，interface也是层层传递，从test到agent再到initiator都有set_interface
    chnl_basic_test.set_interface(chnl0_if,chnl1_if,chnl2_if);
    chnl_burst_test.set_interface(chnl0_if,chnl1_if,chnl2_if);
    chnl_fifo_full_test.set_interface(chnl0_if,chnl1_if,chnl2_if);

    // USER TODO 4.5
    // START TESTs
    chnl_basic_test.run();
    chnl_burst_test.run();
    chnl_fifo_full_test.run();

    $display("*****************all of tests have been finished********************");
    $finish();
  end


endmodule

