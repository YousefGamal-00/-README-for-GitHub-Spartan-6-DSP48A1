    module pipeline_stage 
    #( 
        parameter WIDTH = 8,
        parameter reset_type = "ASYNC",
        parameter sel = 1
    )
    
    (
        input [WIDTH-1:0] DATA_IN,
        input CLK,
        input reset,
        input ENABLE,
        output reg [WIDTH-1:0] DATA_OUT
    );

    generate
        if (sel) 
            begin
                // Registering Data
                if (reset_type == "SYNC") 
                    begin
                            always @(posedge CLK) 
                            begin
                                if (reset)
                                    DATA_OUT <= {WIDTH{1'b0}};   
                                else if (ENABLE)
                                    DATA_OUT <= DATA_IN;
                            end
                    end 

                else if (reset_type == "ASYNC") 
                    begin
                        always @(posedge CLK or posedge reset) 
                        begin
                            if (reset)
                                DATA_OUT <= {WIDTH{1'b0}};   
                            else if (ENABLE)
                                    DATA_OUT <= DATA_IN;
                        end
                    end
            end 

        else 
            begin
                // Bypassing Data
                always @(*) 
                    begin
                        DATA_OUT = DATA_IN;
                    end
            end
    endgenerate

    endmodule









