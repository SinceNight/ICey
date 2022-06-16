module top_module (
    input [15:0] scancode,
    output reg left,
    output reg down,
    output reg right,
    output reg up  ); 
    always@(*)
         begin
            //up = 16'd0;
            //down<=1'b0;
            //left=16'd0;
            //right=16'd0;
            case(scancode)
                16'he06b:left <= 1;          
                default:left=16'd0;
          
                16'he072:down <=1;
           	    default:down=16'd0;
            
                16'he074:right <= 1;
                default:right=16'd0;
        
                16'he075:up <=1;
                default:up=16'd0;
             endcase
         end

endmodule