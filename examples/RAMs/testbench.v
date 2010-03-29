`timescale 1ns/1ps

`define wbclk_period 100
`define async_clk_period 63

`include "output/vlog_constants.v"
`include "../common/wishbone_test_master.v"

module RAM_TEST_MASTER (input wb_clk_i,
			input wb_rst_n_i);
   

   parameter RAM_WIDTH = 32;
   parameter RAM_ASYNC_CLOCK = 0;
   parameter MAX_BLOCK_SIZE = 1024;
   

   wire	     ram_clk;
   reg 	     clk_gen_reg = 1;

   reg [RAM_WIDTH-1:0] buffer [0:MAX_BLOCK_SIZE-1];
   
   reg [31:0] ram_addr = 0;
   reg [RAM_WIDTH-1:0] ram_data_o = 0;
   wire [RAM_WIDTH-1:0] ram_data_i;
   reg 		       ram_rd = 0;
   reg 		       ram_wr = 0;
   reg [RAM_WIDTH/8-1:0] ram_bwsel = 'hff;
   
  
   time 	       last_op_time = 0;
   reg 		       last_op_rw = 0;
   reg [31:0] 	       last_addr = 0;
   reg 		       ready= 0;

   initial begin
      @(posedge wb_rst_n_i);
      #1000 ready = 1;
   end

   if(RAM_ASYNC_CLOCK == 0)
     assign ram_clk = wb_clk_i;
   else begin
     always #(RAM_ASYNC_CLOCK/2) clk_gen_reg = ~clk_gen_reg;
     assign   ram_clk = clk_gen_reg;
   end


   function addr_2_bwsel;
      input [31:0] addr;
      begin
	 case(RAM_WIDTH)
	   8: addr_2_bwsel = 1'b1;
	   16: addr_2_bwsel = (addr[0] ? 2'b01: 2'b10);
	   32: begin
	      case (addr[1:0])
		0: addr_2_bwsel = 4'b1000;
		1: addr_2_bwsel = 4'b0100;
		2: addr_2_bwsel = 4'b0010;
		3: addr_2_bwsel = 4'b0001;
	      endcase // case(addr[1:0])
	   end
	 endcase // case(RAM_WIDTH)
      end
   endfunction // addr_2_bwsel
      

  
   task write_block;

      input [31:0] addr;
      input [3:0] size;
      input [31:0] n_transfers;
      
      begin : ram_writeblk_body
	 integer i;
	 
	 
	 if($time != last_op_time) begin
	    @(posedge ram_clk);
	 end

	 for (i=0;i<n_transfers;i=i+size) begin
	    ram_addr <= (i+addr) >> 2;
	    ram_bwsel <= 4'b1111; //addr_2_bwsel(i+addr);
	    ram_data_o <= buffer[i];

	    ram_wr <= 1;
	    @(posedge ram_clk);
	    ram_wr <= 0;
	 end
	 
	 last_op_time = $time;
      end
   endtask

   task write8; 
      input[31:0] addr; 
      input[7:0] data; 
      begin : write8_body 
	 buffer[0] = data;
	 write_block(addr, 1, 1); 
      end 
   endtask

   task write32; 
      input[31:0] addr; 
      input[31:0] data; 
      begin : write32_body 
	 buffer[0] = data;
	 write_block(addr, 4, 1); 
      end 
   endtask
   
endmodule // RAM_TEST_MASTER


module main;
   reg [31:0] rval;

// generate clocks & reset

   WB_TEST_MASTER WB();
   RAM_TEST_MASTER 
     #(.RAM_ASYNC_CLOCK(67)) 
   RAM1 (
	 .wb_clk_i(WB.wb_clk),
	 .wb_rst_n_i(WB.wb_rst));
   
   
   
   wb_slave_test_rams 
     dut (
	  .rst_n_i  (WB.wb_rst),
	  .wb_clk_i (WB.wb_clk),
	  .wb_addr_i(WB.wb_addr[10:0]),
	  .wb_data_i(WB.wb_data_o),  
	  .wb_data_o(WB.wb_data_i),
	  .wb_cyc_i (WB.wb_cyc),                
	  .wb_sel_i (WB.wb_bwsel),                   
	  .wb_stb_i (WB.wb_stb),                               
	  .wb_we_i  (WB.wb_we),                                
	  .wb_ack_o (WB.wb_ack),                                
	  .clk1_i   (RAM1.ram_clk),
	  .rams_mem1k_addr_i (RAM1.ram_addr[7:0]),
	  .rams_mem1k_data_o (RAM1.ram_data_i),
	  .rams_mem1k_rd_i   (RAM1.ram_rd),
	  .rams_mem1k_data_i (RAM1.ram_data_o),
	  .rams_mem1k_wr_i   (RAM1.ram_wr),
	  .rams_mem1k_bwsel_i(RAM1.ram_bwsel),
	  .rams_mem2k_addr_i (10'b0),
	  .rams_mem2k_data_o (),
	  .rams_mem2k_rd_i   (1'b0)
	  );
   
   integer     i;
   integer fail = 0;
      
   initial begin
      wait(RAM1.ready && WB.ready);

      $display("Test simple bus reads/writes...");

      WB.verbose(1);  
      
      WB.write32(`BASE_RAMS_MEM1K, 32'hdeadbeef);
      WB.write32(`BASE_RAMS_MEM1K + 4, 32'hcafecafe);
      WB.write32(`BASE_RAMS_MEM1K + 'h200, 32'hfacedead);


      WB.read32(`BASE_RAMS_MEM1K, rval);  if(rval != 'hdeadbeef) fail = 1;    
      WB.read32(`BASE_RAMS_MEM1K + 4, rval);if(rval != 'hcafecafe) fail = 1;
      WB.read32(`BASE_RAMS_MEM1K + 'h200, rval);if(rval != 'hfacedead) fail = 1;
      
      
      $display("Test mirrored bus reads/writes...");

      WB.write32(`BASE_RAMS_MEM1K + 16, 32'h55555555);
      WB.read32(`BASE_RAMS_MEM1K + 16, rval);if(rval != 'h55555555) fail = 1;
      
      WB.write32(`BASE_RAMS_MEM1K + 4*`SIZE_RAMS_MEM1K + 16, 32'haaaaaaaa);
      WB.read32(`BASE_RAMS_MEM1K + 16, rval);if(rval != 'haaaaaaaa) fail = 1;


      $display("Byte-access test...");

      WB.verbose(0);
      
      
/*      for(i=0;i<32;i=i+1) WB.write8(`BASE_RAMS_MEM1K + i, i + 1);
      for(i=0;i<32;i=i+1) begin
	WB.read8(`BASE_RAMS_MEM1K + i, rval);
	 if(rval != i+1)
	   fail = 1;
      end
 */
      
/*      
      $display("mem1k: Bus write/mem read test...");
      
      for(i=0;i<256;i=i+1) WB.write32(`BASE_RAMS_MEM1K + i*4, i+1);

      for(i=0;i<256;i=i+1) begin 
 //	 RAM1.read32(i*4, rval);
	 if(rval != i+1) fail =1;
      end
*/
    

  

 
      $display("mem1k: Mem write/bus read test...");
     
      for(i=0;i<256;i=i+1) 
	RAM1.write32(i*4, 257-i);

    

      for(i=0;i<2;i=i+1) begin
	 WB.read32(`BASE_RAMS_MEM1K+i*4, rval);

	 $display(rval);
	 
	 
	 if(rval != 257-i)
	    fail =1;

      end
      end
      
/*
      $display("mem2k: Bus write/mem read test...");

      
      for(i=0;i<512;i=i+1) wb_write(`BASE_RAMS_MEM2K + i*4, 113*i+41);

      @(posedge clk); // sync back to wb clock

      
      for(i=0;i<512;i=i+1) begin 
	 ram2_read(i*4, rval);

	 
	 if(rval != 113*i+41) 
	    fail =1;
      end

      
      if(fail)
	$display("TESTS FAILED");
      else
	$display("TESTS PASSED");
   end
 -----/\----- EXCLUDED -----/\----- */


endmodule
