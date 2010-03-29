// Testbench for Embedded Interrupt Controller (EIC) wbgen2 functionatlity

`timescale 1ns/1ps

`include "../common/wishbone_test_master.v"
`include "output/vlog_constants.v"

module main;
   function [4:0] decode_irq;
      input[31:0] isr_val;
      begin:decode_irq_body
	 
	 integer i;
	 integer irqn;
	 irqn=-1;
	 for(i=0; i<32; i=i+1) if(isr_val[i]) 
	   begin 
	      if(irqn < 0) irqn = i; 
	   end
	 decode_irq = irqn;
      end
   endfunction
    
      

   WB_TEST_MASTER   WB();
   
   wire       clk = WB.wb_clk;
   wire       rst = WB.wb_rst;
     

   wire wb_irq;
   reg 	irq_rising_edge = 0;
   reg 	irq_falling_edge = 1;
   reg 	irq_level_hi = 0;
   reg 	irq_level_lo = 1;
   integer irqn;
   reg [31:0] rval;
   
   
   
   
  wb_test_interrupts
    dut(
	.rst_n_i   (WB.wb_rst),
	.wb_clk_i  (WB.wb_clk),
	.wb_addr_i (WB.wb_addr[1:0]),
	.wb_data_i (WB.wb_data_o),
	.wb_data_o (WB.wb_data_i),
	.wb_cyc_i  (WB.wb_cyc),
	.wb_sel_i  (WB.wb_bwsel),
	.wb_stb_i  (WB.wb_stb),
	.wb_we_i   (WB.wb_we),
	.wb_ack_o  (WB.wb_ack),

	.wb_irq_o  (wb_irq),

	.irq_ipe_i (irq_rising_edge),
	.irq_ine_i  (irq_falling_edge),         
	.irq_il0_i  (irq_level_lo ),            
	.irq_il1_i  (irq_level_hi )
  );


      
   initial begin
      wait (WB.ready);

      $display("Configure the interrupt controller - enable all interrupts");
      WB.write32(`ADDR_TESTIRQ_EIC_IER, 'hf);

// generate some irqs
      #8000; irq_rising_edge = 1;
      #8000; irq_falling_edge = 0;
      #8000; irq_level_lo = 0;
      #8000; irq_level_hi = 1;

      $display("Mask all interrupts");
      
      #8000; WB.write32(`ADDR_TESTIRQ_EIC_IDR, 'hf);

      #8000; irq_level_lo = 0;
      #8000; irq_level_hi = 1;
      
      $display("Test done.");
      
      
      
   end

  
// irq responder
   always@(wb_irq) begin
      if(wb_irq == 1) begin

	 WB.read32(`ADDR_TESTIRQ_EIC_ISR, rval);
	 
	 irqn = decode_irq(rval);
	 
	 $display("Got interrupt: %d", irqn);

	 if(irqn == 2) begin
	    $display("Clearing the 0-level-sensitive interrupt source");
	    irq_level_lo = 1;
	 end

	 if(irqn == 3) begin
	    $display("Clearing the 1-level-sensitive interrupt source");
	    irq_level_hi = 0;
	 end

	 
	 // acknowledge the interrupts
	 WB.write32(`ADDR_TESTIRQ_EIC_ISR, (1<<irqn));
	 $display("Acknowledged IRQ: %d", irqn);
	 
      end
   end


   
endmodule
