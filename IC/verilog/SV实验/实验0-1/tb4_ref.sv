`timescale 1ns/1ps

// 注意，sv下函数可能写在例化的后面！
module chnl_initiator(          // 在模块中写入函数来直接使用，将initiator进行封装，然后通过例化模块chnl1,2,3来实现。实际上还是硬件逻辑；而tab3是通过代码来实现，更像软件逻辑。
  input               clk,      // initiator内部包括write，idle，set_name，他是独立于tb的单独的模块
  input               rstn,     // 它涵盖了tb3中的发送激励(valid=1),置零(idle)功能
  output logic [31:0] ch_data,
  output logic        ch_valid,
  input               ch_ready,
  input        [ 5:0] ch_margin
);

string name;

function void set_name(string s);
  name = s;
endfunction

task chnl_write(input logic[31:0] data);
  // USER TODO
  // drive valid data
  // ...
  @(posedge clk);
  ch_valid <= 1;
  ch_data <= data;
  @(negedge clk);
  wait(ch_ready === 'b1);
  $display("%t channel initial [%s] sent data %x", $time, name, data);
  chnl_idle();    // 下降沿——>上升沿，此处调用了idle程序，所以还是存在valid->0
endtask

task chnl_idle();
  // USER TODO
  // drive idle data
  // ...
  @(posedge clk);
  ch_valid <= 0;
  ch_data <= 0; // 在上升沿也存在valid=0
endtask

endmodule

module tb4_ref;  // mcdt的例化也在tb下，mcdt应该有缩进才对
logic         clk;
logic         rstn;
logic [31:0]  ch0_data;
logic         ch0_valid;
logic         ch0_ready;
logic [ 5:0]  ch0_margin;
logic [31:0]  ch1_data;
logic         ch1_valid;
logic         ch1_ready;
logic [ 5:0]  ch1_margin;
logic [31:0]  ch2_data;
logic         ch2_valid;
logic         ch2_ready;
logic [ 5:0]  ch2_margin;
logic [31:0]  mcdt_data;
logic         mcdt_val;
logic [ 1:0]  mcdt_id;

mcdt dut(
   .clk_i(clk)
  ,.rstn_i(rstn)
  ,.ch0_data_i(ch0_data)
  ,.ch0_valid_i(ch0_valid)
  ,.ch0_ready_o(ch0_ready)
  ,.ch0_margin_o(ch0_margin)
  ,.ch1_data_i(ch1_data)
  ,.ch1_valid_i(ch1_valid)
  ,.ch1_ready_o(ch1_ready)
  ,.ch1_margin_o(ch1_margin)
  ,.ch2_data_i(ch2_data)
  ,.ch2_valid_i(ch2_valid)
  ,.ch2_ready_o(ch2_ready)
  ,.ch2_margin_o(ch2_margin)
  ,.mcdt_data_o(mcdt_data)
  ,.mcdt_val_o(mcdt_val)
  ,.mcdt_id_o(mcdt_id)
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

logic [31:0] chnl0_arr[];
logic [31:0] chnl1_arr[];
logic [31:0] chnl2_arr[];
// USER TODO
// generate 100 data for each dynamic array
initial begin
  chnl0_arr = new[100];
  chnl1_arr = new[100];
  chnl2_arr = new[100];
  foreach(chnl0_arr[i]) begin  // 遍历循环100个数 i=0~99
  chnl0_arr[i] = 'h00C0_00000 + i;
	chnl1_arr[i] = 'h00C1_00000 + i;
	chnl2_arr[i] = 'h00C2_00000 + i;
  end
end

// USER TODO
// use the dynamic array, user would send all of data
// data test
initial begin 
  @(posedge rstn);
  repeat(5) @(posedge clk);
  chnl0_init.set_name("chnl0_init");  // 调用chnl_init，注意，调用前必须例化
  chnl1_init.set_name("chnl1_init");
  chnl2_init.set_name("chnl2_init");
  
  // channel 0 test
  // TODO use chnl0_arr to send all data   // 这里将数据chnl0_arr[i]发送到了chnl_write
  foreach(chnl0_arr[i]) chnl0_init.chnl_write(chnl0_arr[i]);

  // channel 1 test
  // TODO use chnl1_arr to send all data
  foreach(chnl1_arr[i]) chnl1_init.chnl_write(chnl1_arr[i]);

  // channel 2 test
  // TODO use chnl2_arr to send all data
  foreach(chnl2_arr[i]) chnl2_init.chnl_write(chnl2_arr[i]);
end


chnl_initiator chnl0_init(    // 将chnl_write封装进了initiator中，此处需要将chnl_init与tb相连，因为是对tb发送激励
  .clk      (clk),
  .rstn     (rstn),
  .ch_data  (ch0_data),
  .ch_valid (ch0_valid),
  .ch_ready (ch0_ready),
  .ch_margin(ch0_margin) 
);

chnl_initiator chnl1_init(
  .clk      (clk),
  .rstn     (rstn),
  .ch_data  (ch1_data),
  .ch_valid (ch1_valid),
  .ch_ready (ch1_ready),
  .ch_margin(ch1_margin) 
);

chnl_initiator chnl2_init(
  .clk      (clk),
  .rstn     (rstn),
  .ch_data  (ch2_data),
  .ch_valid (ch2_valid),
  .ch_ready (ch2_ready),
  .ch_margin(ch2_margin) 
);

endmodule

