module fuzhi;
reg A,B,C;
initial
begin
        A=0;B=1;C=0;
        #100 A=1;B=0;
        #100 A=0;C=1;
        #100 B=1;
        #100 C=0;
        $display(B);
        $finish;    //输出的时候必须这两个语句一起上
    end
endmodule