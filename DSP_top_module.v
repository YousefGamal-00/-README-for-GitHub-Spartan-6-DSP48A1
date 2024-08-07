module DSP_top_module
#(
    /*-----specify the number of pipeline registers for input paths.-----*/

    parameter A0REG       = 0 ,  /* no register  */
    parameter A1REG       = 1 ,  /* one register */
    parameter B0REG       = 0 ,  /* no register  */
    parameter B1REG       = 1 ,  /* one register */
    parameter CREG        = 1 ,  /* one register */
    parameter DREG        = 1 ,  /* one register */
    parameter MREG        = 1 ,  /* one register */
    parameter PREG        = 1 ,  /* one register */ 
    parameter CARRYINREG  = 1 ,  /* one register */ 
    parameter CARRYOUTREG = 1 ,  /* one register */
    parameter OPMODEREG   = 1 ,  /* one register */

    /*---determine the carry cascade input source, Values CARRYIN or opcode[5].---*/
    /*---If neither "CARRYIN" nor "OPMODE5" is set, the output is tied to 0.---*/
    parameter CARRYINSEL = "OPMODE5" , /* default value */ 

    /*----specifies the source of the input to the B port------*/
    /*----DIRECT: The B port gets its input directly from the B input of the slice.---*/
    /*---CASCADE: The B port gets its input from the BCIN (B cascaded input) of the previous DSP48A1 slice.--*/
    /*------ else ==> the mux output should be Zero ------*/
     parameter B_INPUT = "DIRECT" ,

     /*--determines the reset for the DSP48A1 slice is synchronous or asynchronous--*/
     /*--ASYNC: Resets occur asynchronously----- */
     /*--SYNC : Resets occur synchronously------*/
    parameter RSTTYPE = "SYNC" ,

    /*parameters for cascading DSP48A1*/
    parameter BCIN_val  = 18'd2024 
)

(
    /*--------------------input and output ports---------------------*/

    input CLK      , /*--DSP clock--*/
    input [7: 0]OPMODE , /*--Control input to select the arithmetic operations of the DSP48A1 slice--*/
    input [17:0] A , /* input to multiplier && optionally to postadder/subtracter depending on OPMODE[1:0].*/
    input [17:0] B , /* pre-adder/subtractorinput/ multiplier based on OPMODE[4]/ post-adder/subtractor based on OPMODE[1:0].*/
    input [17:0] D , /* pre-adder/subtracter input |  D[11:0] are concatenated with A and B and optionally */
                     /*sent to post-adder/subtracter depending on the value of OPMODE[1:0]. */

    input [47:0] C , /* input to post-adder/subtracter*/
    input CARRYIN  , /* carry input to the post-adder/subtracter*/

    input CEA            ,   /*Clock enable for the A port registers:        (A0REG & A1REG). */                     
    input CEB            ,   /*Clock enable for the B port registers:        (B0REG & B1REG). */                     
    input CEC            ,   /*Clock enable for the C port registers:        (CREG). */                     
    input CED            ,   /*Clock enable for the D port registers:        (DREG). */                     
    input CEM            ,   /*Clock enable for the multiplier registers:    (MREG). */ 
    input CEP            ,   /*Clock enable for the P output port registers: (PREG = 1). */   
    input CEOPMODE       ,   /*Clock enable for the opmode register (OPMODEREG).*/
    input CECARRY_IN_OUT ,   /*Clock enable for the carry-in register and the carry-out register.*/               


/*-----All the resets are active high reset. sync or async depending on the parameter RSTTYPE----*/      

    input RSTA             ,   /*Reset for the A registers: (A0REG & A1REG).*/
    input RSTB             ,   /*Reset for the B registers: (B0REG & B1REG).*/
    input RSTC             ,   /*Reset for the C registers: (CREG).*/
    input RSTCARRY_IN_OUT  ,   /*Reset for the carry-in register and the carry-out register*/
    input RSTD             ,   /*Reset for the D register (DREG)*/
    input RSTM             ,   /*Reset for the multiplier register (MREG)*/
    input RSTOPMODE        ,   /*Reset for the opmode register (OPMODEREG).*/
    input RSTP             ,   /*Reset for the P output registers (PREG = 1).*/

    input [47:0] PCIN      ,  /*Cascade input for Port P.*/
    input [17:0] BCIN      ,  /*Cascade input for Port B.*/

    
    output  [17:0]BCOUT ,  /*Cascade output for Port B.*/
    output  [47:0]PCOUT ,  /*Cascade output for Port P.*/

    output  [35:0] M ,    /* buffered multiplier data output*/
                         /*  MREG = 1 ==> output of multiplier is registered */ 
                         /*  MREG = 0 ==> Direct output of multiplier */ 

    output  [47:0] P , /*output of post adder/subtractor */
                         /*  PREG = 1 ==> output is registered */ 
                         /*  PREG = 0 ==> Direct output  */ 

    output  CARRYOUT , /*carry out signal from post-adder/subtracter*/                        
                        /*  CARRYOUTREG = 1 ==> output is registered */ 
                        /*  CARRYOUTREG = 0 ==> Direct output  */ 

    output  CARRYOUTF  /*It is a copy of the CARRYOUT signal */

);

/*--------------------instantiate the pipelines stages-----------------*/
/*------------------parameters(WIDTH , reset_type , sel)-----------------*/
/*------inputs(DATA_IN , CLK , reset , ENABLE) ------outputs(DATA_OUT)--------*/

wire signed [17:0] D_stage_out , A0_stage_out , A1_stage_out , B0_stage_out , B1_stage_out ;
wire signed [47:0] C_stage_out ;
wire signed [7 :0] OPMODE_stage_out ;

pipeline_stage #(.WIDTH(18) , .reset_type(RSTTYPE) , .sel(DREG) ) D_STAGE
( .DATA_IN(D)  , .CLK(CLK)  , .reset(RSTD)  , .ENABLE(CED) , .DATA_OUT(D_stage_out) ) ;

generate 
      if(B_INPUT == "DIRECT")
          begin : direct_case
              pipeline_stage #(.WIDTH(18) , .reset_type(RSTTYPE) , .sel(B0REG) ) B0_STAGE
              ( .DATA_IN(B)  , .CLK(CLK)  , .reset(RSTB)  , .ENABLE(CEB) , .DATA_OUT(B0_stage_out) ) ;      
          end

      else if (B_INPUT == "CASCADE")
          begin : cascade_case       
              pipeline_stage #(.WIDTH(18) , .reset_type(RSTTYPE) , .sel(B0REG) ) B0_STAGE
              ( .DATA_IN(BCIN_val)  , .CLK(CLK)  , .reset(RSTB)  , .ENABLE(CEB) , .DATA_OUT(B0_stage_out) ) ;
            end   

      else
          begin : default_case
              assign B0_stage_out = 18'h00000;
          end
endgenerate 

  pipeline_stage #(.WIDTH(18) , .reset_type(RSTTYPE) , .sel(A0REG) ) A0_STAGE
  ( .DATA_IN(A)  , .CLK(CLK)  , .reset(RSTA)  , .ENABLE(CEA) , .DATA_OUT(A0_stage_out) ) ;      

  pipeline_stage #(.WIDTH(48) , .reset_type(RSTTYPE) , .sel(CREG) ) C_STAGE
  ( .DATA_IN(C)  , .CLK(CLK)  , .reset(RSTC)  , .ENABLE(CEC) , .DATA_OUT(C_stage_out) ) ;     

    pipeline_stage #(.WIDTH(8) , .reset_type(RSTTYPE) , .sel(OPMODEREG) ) OPMODE_STAGE
  ( .DATA_IN(OPMODE)  , .CLK(CLK)  , .reset(RSTOPMODE)  , .ENABLE(CEOPMODE) , .DATA_OUT(OPMODE_stage_out) ) ;      
 

 reg [17:0] pre_adder_sub_output_stage  , B1_stage_in ;

 always@(*)
 begin
        if(OPMODE_stage_out[6])
              pre_adder_sub_output_stage = D_stage_out - B0_stage_out ;
        else
              pre_adder_sub_output_stage = D_stage_out + B0_stage_out ;

                if( OPMODE_stage_out[4] )
                       B1_stage_in = pre_adder_sub_output_stage ;
                 else
                       B1_stage_in = B0_stage_out ;
   
 end

    pipeline_stage #(.WIDTH(18) , .reset_type(RSTTYPE) , .sel(B1REG) ) B1_STAGE
  ( .DATA_IN(B1_stage_in)  , .CLK(CLK)  , .reset(RSTB)  , .ENABLE(CEB) , .DATA_OUT(B1_stage_out) ) ;

  assign BCOUT = B1_stage_out ;       

    pipeline_stage #(.WIDTH(18) , .reset_type(RSTTYPE) , .sel(A1REG) ) A1_STAGE
  ( .DATA_IN(A0_stage_out)  , .CLK(CLK)  , .reset(RSTA)  , .ENABLE(CEA) , .DATA_OUT(A1_stage_out) ) ;   


wire signed [35:0] mutliplier_stage_out  ;

assign mutliplier_stage_out = A1_stage_out * B1_stage_out ; 

    pipeline_stage #(.WIDTH(36) , .reset_type(RSTTYPE) , .sel(MREG) ) M_STAGE
  ( .DATA_IN(mutliplier_stage_out)  , .CLK(CLK)  , .reset(RSTM)  , .ENABLE(CEM) , .DATA_OUT(M) ) ;      



wire current_carry_in ;

generate

    if(CARRYINSEL == "OPMODE5")
        assign current_carry_in = OPMODE_stage_out[5] ;

    else if(CARRYINSEL == "CARRYIN")
        assign current_carry_in = CARRYIN ;

endgenerate 

wire CIN ;

    pipeline_stage #(.WIDTH(1) , .reset_type(RSTTYPE) , .sel(CARRYINREG) ) CYI_STAGE
  ( .DATA_IN(current_carry_in)  , .CLK(CLK)  , .reset(RSTCARRY_IN_OUT)  , .ENABLE(CECARRY_IN_OUT) , .DATA_OUT(CIN) ) ;     

  reg [47:0] Z_mux_stage_out, X_mux_stage_out;
  reg [47:0] post_adder_sub_output_stage; 
  reg [48:0] post_adder_sub_temp ; 
  reg CYO_in;

always@(*)
  begin
        case( {OPMODE_stage_out[3] , OPMODE_stage_out[2] } )

            2'b00: Z_mux_stage_out = 48'h000000000000 ;
            2'b01: Z_mux_stage_out = PCIN ;    
            2'b10: Z_mux_stage_out = P ;  
            2'b11: Z_mux_stage_out = C_stage_out ; 

        endcase

        case( {OPMODE_stage_out[1] , OPMODE_stage_out[0] } )

            2'b00: X_mux_stage_out = 48'h000000000000 ;
            2'b01: X_mux_stage_out = { { 12{mutliplier_stage_out[35]} } , mutliplier_stage_out } ;   
            2'b10: X_mux_stage_out =  P ; 
            2'b11: X_mux_stage_out = { D_stage_out[11:0] ,  A1_stage_out[17:0] ,  B1_stage_out[17:0] } ;

        endcase    

       if( OPMODE_stage_out[7] )

            post_adder_sub_temp  = Z_mux_stage_out - (X_mux_stage_out + CIN)  ;     
     else
            post_adder_sub_temp = Z_mux_stage_out + X_mux_stage_out + CIN  ; 

            post_adder_sub_output_stage = post_adder_sub_temp[47 : 0] ;
            CYO_in  = post_adder_sub_temp[48] ;
                
  end 

    pipeline_stage #(.WIDTH(1) , .reset_type(RSTTYPE) , .sel(CARRYOUTREG) ) CYO_STAGE
  ( .DATA_IN(CYO_in)  , .CLK(CLK)  , .reset(RSTCARRY_IN_OUT)  , .ENABLE(CECARRY_IN_OUT) , .DATA_OUT(CARRYOUT) ) ;     

    assign CARRYOUTF = CARRYOUT ;

    pipeline_stage #(.WIDTH(48) , .reset_type(RSTTYPE) , .sel(PREG) ) P_STAGE
  ( .DATA_IN(post_adder_sub_output_stage)  , .CLK(CLK)  , .reset(RSTP)  , .ENABLE(CEP) , .DATA_OUT(P) ) ;

  assign PCOUT = P ;     


endmodule
