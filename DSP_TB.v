/* This testbench is done for some default value */
/* if we need to change it pass the required paramter to DUT and change the delay */
/* Defaults ==> A0  , B0 are not exist */
/* Defaults ==> carry in is opmode [5] */
/* Defaults ==> disable cascading for port B*/
/* Defaults ==> synchronous reset*/

module DSP_tb ;

    reg CLK ;
    reg [7: 0]OPMODE ; 
    reg [17:0] A  , B , D ;
    reg [17:0] BCIN  ;  
    reg [47:0] PCIN  ;  
    reg [47:0] C ; 
    reg CARRYIN  ; 
    reg CEA ,CEB , CEC , CED , CEM ,  CEP ;  
    reg CEOPMODE ;   
    reg CECARRY_IN_OUT ;                     
    reg RSTA , RSTB , RSTC , RSTD , RSTM , RSTP ;  
    reg RSTCARRY_IN_OUT  ;   
    reg RSTOPMODE ;   

    wire  [17:0]BCOUT ;  
    wire  [47:0]PCOUT ;  
    wire  [35:0] M ; 
    wire  [47:0] P ;
    wire  CARRYOUT ;
    wire  CARRYOUTF ;

    reg  [17:0]BCOUT_expected ;  
    reg  [47:0]PCOUT_expected ;  
    reg  [35:0] M_expected ; 
    reg  [47:0] P_expected ;
    reg  CARRYOUT_expected ;
    reg  CARRYOUTF_expected ;

DSP_top_module DUT (.*) ;

always
    begin
        CLK = 0 ;
        #10 ;    
        CLK = 1 ;
        #10 ;    
    end

initial 

    begin

    $display("         start simulation :) ");
    $display(" =================================== ");

  /*-----initialize Data ports to Zero at -Ve edge CLock  -------*/  
@(negedge CLK) ;
A = 0  ; B = 0  ;  D = 0  ;   C = 0;
CEA = 0; CEB = 0; CEC = 0;
CED = 0; CEM = 0; CEP = 0;
RSTOPMODE = 0; RSTCARRY_IN_OUT = 0;
CARRYIN   = 0; OPMODE = 0;
CEOPMODE  = 0; CECARRY_IN_OUT = 0;
RSTA = 0; RSTB = 0; RSTC = 0;
RSTD = 0; RSTM = 0; RSTP = 0;
BCIN = 0; PCIN = 0;

repeat(2)@(negedge CLK) ; // hold the data for 2 clock cycles

 /* Check the reset functionality */
/* Initialize reset by 1*/
        RSTA = 1; RSTB = 1; RSTC = 1;
        RSTD = 1; RSTM = 1; RSTP = 1;
        RSTOPMODE = 1; RSTCARRY_IN_OUT = 1;

/* ----------Expect the all output signals to be Zero------- */

BCOUT_expected = 18'h00000 ;    PCOUT_expected = 48'h000000000000 ;  
M_expected = 36'h000000000 ;    P_expected = 48'h000000000000 ;
CARRYOUT_expected  = 1'b0  ;    CARRYOUTF_expected = 1'b0 ;

 @(negedge CLK); // synchronous the outputs with -Ve edge Clock
      
        if (
            BCOUT_expected != BCOUT || PCOUT_expected != PCOUT || M_expected != M_expected ||
            P_expected != P || CARRYOUT_expected != CARRYOUT || CARRYOUTF_expected != CARRYOUTF
           )
        begin
              $display("Error for reset at time : %t" , $time);
        end

 /*-----------------checking for adders/subtractors and multiplier using direct cases----------------*/
 /*-------------------------------------- Disable the reset -----------------------------------------*/
 /*-------------------------------------- Direct case one add / add-----------------------------------------*/

@(negedge CLK) ; // stimulate at -Ve edge Clock

RSTA = 0; RSTB = 0; RSTC = 0;
RSTD = 0; RSTM = 0; RSTP = 0;
RSTOPMODE = 0; RSTCARRY_IN_OUT = 0;

CEA  = 1 ; CEB  = 1 ;  CEC  = 1 ;                               
CEM  = 1 ; CEP  = 1 ;  CED  = 1 ;                               
CEOPMODE = 1 ;  CECARRY_IN_OUT = 1 ;     

D = 18'd10 ; B = 18'd20 ; A = 18'd40 ;  OPMODE[6] = 0 ; OPMODE[4] = 1  ; 
// addition and pass the value (30) to multiplier which pass the value( 40*(10+20) )
M_expected = 1200 ;   BCOUT_expected = 30 ;
OPMODE[1:0] = 2'b01 ; // pass the value (1200)
OPMODE[3:2] = 2'b00 ; // add Zero with the value 1200 
OPMODE[7]  = 0 ; // addition op
OPMODE[5] = 1 ; // carry in ==> the addition will be 1201
P_expected = 48'd1201 ; PCOUT_expected = 1201; 
CARRYOUT_expected = 0 ;
CARRYOUTF_expected = 0 ;

repeat(4)@(negedge CLK) ; // synchronous the output with delay of registers

        if (
            BCOUT_expected != BCOUT || PCOUT_expected != PCOUT || M_expected != M ||
            P_expected != P || CARRYOUT_expected != CARRYOUT || CARRYOUTF_expected != CARRYOUTF
           )
        begin
              $display("Error for arithmatic operations at time : %t" , $time);
        end

/*---------------------------------------Direct case two pass then add---------------------------------------------------*/ 

@(negedge CLK) ; // stimulate at -Ve edge Clock

B = 18'd46 ; A = 18'd10 ;  OPMODE[4] = 0  ; 
// pass the value (46) to multiplier which passes the value( 10*(46) )
M_expected = 460 ;   BCOUT_expected = 46 ;
OPMODE[1:0] = 2'b01 ; // pass the value (460)
OPMODE[3:2] = 2'b00 ; // add Zero with the value 460
OPMODE[7]  = 0 ; // add op
OPMODE[5] = 1 ; // carry in ==> the subtraction will be 461

P_expected = 48'd461 ; PCOUT_expected = 48'd461; 
CARRYOUT_expected = 0 ;
CARRYOUTF_expected = 0 ;

repeat(4)@(negedge CLK) ; // synchronous the output with delay of registers

        if (
            BCOUT_expected != BCOUT || PCOUT_expected != PCOUT || M_expected != M ||
            P_expected != P || CARRYOUT_expected != CARRYOUT || CARRYOUTF_expected != CARRYOUTF
           )
        begin
              $display("Error for arithmatic operations at time : %t" , $time);
        end



/*---------------------------------------Direct case three sub then add---------------------------------------------------*/ 

@(negedge CLK) ; // stimulate at -Ve edge Clock

D = 18'd50 ; B = 18'd35 ; A = 18'd10 ;  OPMODE[4] = 1  ;  OPMODE[6] = 1  ; 
// pass the value (15) to multiplier which passes the value( 10*(50-35) )
M_expected = 150 ;   BCOUT_expected = 15 ;
OPMODE[1:0] = 2'b01 ; // pass the value (150)
OPMODE[3:2] = 2'b00 ; // add Zero with the value 150
OPMODE[7]  = 0 ; // add op
OPMODE[5] = 1 ; // carry in ==> the subtraction will be 151

P_expected = 48'd151 ; PCOUT_expected = 48'd151; 
CARRYOUT_expected = 0 ;
CARRYOUTF_expected = 0 ;

repeat(4)@(negedge CLK) ; // synchronous the output with delay of registers

        if (
            BCOUT_expected != BCOUT || PCOUT_expected != PCOUT || M_expected != M ||
            P_expected != P || CARRYOUT_expected != CARRYOUT || CARRYOUTF_expected != CARRYOUTF
           )
        begin
              $display("Error for arithmatic operations at time : %t" , $time);
        end

/*---------------------------------------Direct case Four sub / add ---------------------------------------------------*/ 

@(negedge CLK); // stimulate at -Ve edge Clock

D = 18'd1000 ; B = 18'd200 ; A = 18'd4 ;  OPMODE[6] = 1 ; OPMODE[4] = 1  ; 
// subtrcation and pass the value (800) to multiplier which pass the value( 4*(1000 - 200) )
M_expected = 3200 ;   BCOUT_expected = 800 ;
OPMODE[1:0] = 2'b01 ; // pass the value (3200)
C = 48'd1200; 
OPMODE[3:2] = 2'b11 ; // add C + M + cin
OPMODE[7]  = 0 ; // addition op
OPMODE[5] = 1 ; // carry in ==> the subtraction will be 4401

P_expected = 48'd4401 ; PCOUT_expected = 48'd4401 ; 
CARRYOUT_expected = 0 ;
CARRYOUTF_expected = 0 ;

repeat(4)@(negedge CLK) ; // synchronous the output with delay of registers

        if (
            BCOUT_expected != BCOUT || PCOUT_expected != PCOUT || M_expected != M ||
            P_expected != P || CARRYOUT_expected != CARRYOUT || CARRYOUTF_expected != CARRYOUTF
           )
        begin
              $display("Error for arithmatic operations at time : %t" , $time);
        end


/*---------------------------------------Direct case five sub / sub  ---------------------------------------------------*/ 

@(negedge CLK); // stimulate at -Ve edge Clock

D = 18'd1000 ; B = 18'd200 ; A = 18'd4 ;  OPMODE[6] = 1 ; OPMODE[4] = 1  ; 
// subtrcation and pass the value (800) to multiplier which pass the value( 4*(1000 - 200) )
M_expected = 3200 ;   BCOUT_expected = 800 ;
OPMODE[1:0] = 2'b01 ; // pass the value (3200)
C = 48'd5600; 
OPMODE[3:2] = 2'b11 ; // add C - M - cin
OPMODE[7]  = 1 ; // subtraction op
OPMODE[5] = 1 ; // carry in ==> the subtraction will be 4401

P_expected = 48'd2399 ; PCOUT_expected = 48'd2399 ; 
CARRYOUT_expected = 0 ;
CARRYOUTF_expected = 0 ;

repeat(4)@(negedge CLK) ; // synchronous the output with delay of registers

        if (
            BCOUT_expected != BCOUT || PCOUT_expected != PCOUT || M_expected != M ||
            P_expected != P || CARRYOUT_expected != CARRYOUT || CARRYOUTF_expected != CARRYOUTF
           )
        begin
              $display("Error for arithmatic operations at time : %t" , $time);
        end


/*---------------------------------------Last Direct case  sub / sub  for -Ve numbers ---------------------------------------------------*/ 

@(negedge CLK); // stimulate at -Ve edge Clock

D = -18'd500 ; B = 18'd200 ; A = 18'd5 ;  OPMODE[6] = 1 ; OPMODE[4] = 1  ; 
// subtrcation and pass the value (-700) to multiplier which pass the value( 5*(-500 - 200) )
M_expected = -3500 ;   BCOUT_expected = -700 ;
OPMODE[1:0] = 2'b01 ; // pass the value (-3500)
C = 48'd5600; 
OPMODE[3:2] = 2'b11 ; // add C - M - cin
OPMODE[7]  = 1 ; // subtraction op
OPMODE[5] = 1 ; // carry in ==> the subtraction will be 4401

P_expected = 48'h00000000238B ; PCOUT_expected =  48'h00000000238B ; // this values for Sign extension operation 
CARRYOUT_expected = 1;
CARRYOUTF_expected = 1 ;

repeat(4)@(negedge CLK) ; // synchronous the output with delay of registers

        if (
            BCOUT_expected != BCOUT || PCOUT_expected != PCOUT || M_expected != M ||
            P_expected != P || CARRYOUT_expected != CARRYOUT || CARRYOUTF_expected != CARRYOUTF
           )
        begin
              $display("Error for arithmatic operations at time : %t" , $time);
        end




$display("---- The testbench is done successfully :) --------");
$stop;
    end
endmodule

