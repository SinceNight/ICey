function int double(input a);
    return 2*a;
endfunction
initial begin
    $display(10,double(10));
end