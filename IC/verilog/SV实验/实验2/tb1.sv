`timescale 1ns/1ps

interface chnl_intf(input clk, input rstn); // clk rstn需要外部(tb)驱动，因此写进参数。
  logic [31:0] ch_data;            // interface的内部信号不需要写inout，有时候为了验证通过modport来进行区分。
  logic        ch_valid;
  logic        ch_ready;
  logic [ 5:0] ch_margin;
  clocking drv_ck @(posedge clk); // 通过clocking来提前采样和延后驱动，避免竞争。
    default input #1ns output #1ns;
    output ch_data, ch_valid;
    input ch_ready, ch_margin;   // 定义需要提前和延后的数据。
  endclocking
endinterface

module chnl_initiator(chnl_intf intf);   // 接口例化 chnl_intf intf;此处的intf相当于形参，例化后有自己的名字成为实参。
  string name;
  int idle_cycles = 1;
  function automatic void set_idle_cycles(int n);
    idle_cycles = n;
  endfunction
  function automatic void set_name(string s);
    name = s;
  endfunction
  task automatic chnl_write(input logic[31:0] data);   
    @(posedge intf.clk); // 引用接口的时钟。
    intf.drv_ck.ch_valid <= 1;   // 通过clocking来驱动，这样就可以启动延时，对接口做了intf的例化，所以是调用intf！！！！！！
    intf.drv_ck.ch_data <= data;
    wait(intf.ch_ready === 'b1);
    $display("%t channel initiator [%s] sent data %x", $time, name, data);
    repeat (idle_cycles) chnl_idle(); // 再n次idle_cycles后执行程序，可以直接让idle_cycles的数量为0.
  endtask
  task automatic chnl_idle();
    @(posedge intf.clk);
    clocking bus @(posedge intf.clk);
    default input #10ns output #2ns;
    input ready,maring;
    output data,valid;
    endclocking
    intf.ch_valid <= 0;
    intf.ch_data <= 0;
  endtask
endmodule

module chnl_generator;     // generator模块产生数据，类似试验1的动态数组，仅供调用。
  int chnl_arr[$];
  int num;
  int id;
  function automatic void initialize(int n);
    id = n;
    num = 0;
  endfunction
  function automatic int get_data();
    int data;
    data = 'h00C0_0000 + (id<<16) + num;
    num++;
    chnl_arr.push_back(data);
    return data;
  endfunction
endmodule

module tb1;  // 例化
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
  
  initial begin 
    // verification component initializationi
    chnl0_gen.initialize(0);  // 初始化，调用函数生成数据,根据不同的id使得initiator获得不同数据，此处的chnl0是chnl_gen例化结果
    chnl1_gen.initialize(1);
    chnl2_gen.initialize(2);
    chnl0_init.set_name("chnl0_init"); //调用函数生成名字
    chnl1_init.set_name("chnl1_init");
    chnl2_init.set_name("chnl2_init");
    chnl0_init.set_idle_cycles(0);// 连续发送数据
    chnl1_init.set_idle_cycles(0);
    chnl2_init.set_idle_cycles(0);   
  end

  initial begin
    @(posedge rstn);
    repeat(5) @(posedge clk);
    repeat(100) begin
      chnl0_init.chnl_write(chnl0_gen.get_data());      //此处发送了信号
    end
    chnl0_init.chnl_idle(); 
  end
 
  initial begin
    @(posedge rstn);
    repeat(5) @(posedge clk);  // 等五次上升沿后触发
    repeat(100) begin         //  且连续触发100次
      chnl1_init.chnl_write(chnl1_gen.get_data());  
    end
    chnl1_init.chnl_idle(); 
  end

  initial begin
    @(posedge rstn);
    repeat(5) @(posedge clk);
    repeat(100) begin
      chnl2_init.chnl_write(chnl2_gen.get_data());
    end
    chnl2_init.chnl_idle(); 
  end
  
  chnl_intf chnl0_if(.*);      // interface和module都需要例化，tb1与mcdt已经在上面例化了。这里的chnl0_if和下面的chnl_init一样，都是自己定义的名字。
  chnl_intf chnl1_if(.*);
  chnl_intf chnl2_if(.*);

  chnl_initiator chnl0_init(chnl0_if);  // 和实验1 tb4一样，将initiator通过接口例化DUT，此处对initiator连接了interface的实例，109行可以直接调用。  此处使程序运行
  chnl_initiator chnl1_init(chnl1_if);  // 此处调用initiator,创建chnl1_init实例，并赋予chnl1_if接口。
  chnl_initiator chnl2_init(chnl2_if);

  chnl_generator chnl0_gen();
  chnl_generator chnl1_gen();
  chnl_generator chnl2_gen();   // 此处创建一个generator的句柄，调用genrator来帮助initiator拿到数据。

endmodule

