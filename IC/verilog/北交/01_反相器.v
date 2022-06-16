module inv(A,Y); //A,Y为端口
    input  A;
    output Y;
    assign Y=~A;
endmodule
