`timescale 1ns/1ps

`include "output/vlog_constants.v"
`include "../common/wishbone_test_master.v"

`define FIFO_FULL 16
`define FIFO_EMPTY 17

module main;


   reg tsf_wr_req  = 0;
   
   wire tsf_wr_full;
   wire tsf_wr_empty;
   wire [7:0] tsf_wr_usedw;
   
   reg [27:0] tsf_val_r;
   reg [3:0]  tsf_val_f;
   reg [4:0]  tsf_pid;
   reg [15:0]  tsf_fid;
	
	
   reg memacc_rd_req = 0;
   wire memacc_rd_full;
   wire memacc_rd_empty;
   
   wire [4:0] memacc_rd_usedw;
   
   wire memacc_ad_sel ;
   wire [31:0] memacc_ad ;
   
   WB_TEST_MASTER WB();
   
  
   wire clk = WB.wb_clk;
   wire rst = WB.wb_rst;

	
   wb_test_fifos 
     dut (
	  .rst_n_i    (WB.wb_rst),       
	  .wb_clk_i          (WB.wb_clk),
	  .wb_addr_i         (WB.wb_addr[2:0]),
	  .wb_data_i         (WB.wb_data_o),
	  .wb_data_o         (WB.wb_data_i),
	  .wb_cyc_i          (WB.wb_cyc),
	  .wb_sel_i          (WB.wb_bwsel),
	  .wb_stb_i          (WB.wb_stb),
	  .wb_we_i           (WB.wb_we),
	  .wb_ack_o          (WB.wb_ack),
	  .ft_tsf_wr_req_i   (tsf_wr_req),      
	  .ft_tsf_wr_full_o                   (tsf_wr_full),    
	  .ft_tsf_wr_empty_o                      (tsf_wr_empty),
	  .ft_tsf_wr_usedw_o                      (tsf_wr_usedw),
	  .ft_tsf_val_r_i                         (tsf_val_r),
	  .ft_tsf_val_f_i                         (tsf_val_f),
	  .ft_tsf_pid_i                           (tsf_pid),
	  .ft_tsf_fid_i                           (tsf_fid),
	  .ft_memacc_rd_req_i                   (memacc_rd_req),    
	  .ft_memacc_rd_full_o                      (memacc_rd_full),
	  .ft_memacc_rd_empty_o                     (memacc_rd_empty),
	  .ft_memacc_rd_usedw_o                     (memacc_rd_usedw),
	  .ft_memacc_ad_sel_o                       (memacc_ad_sel),
	  .ft_memacc_ad_o                           (memacc_ad)
	  );


   reg [31:0] memacc_prev_addr  = 'hffffffff;

   task wait_fifo_flag(input [31:0] cr_addr, input [31:0] flag, input value);
     begin: fifo_full_body
	reg [31:0] cr_val;

	WB.read32(cr_addr, cr_val);
	
	while(cr_val[flag] != value) 
	  WB.read32(cr_addr, cr_val);
	   
	
     end
   endtask


   // writes from the host side to MEMACC fifo
   task memacc_write( input [31:0] address,
		      input [31:0] data);

      begin


      if(memacc_prev_addr + 1 != address)
	begin
	   wait_fifo_flag(`ADDR_FT_MEMACC_CSR, `FIFO_FULL, 0);
	   WB.write32(`ADDR_FT_MEMACC_R0, 0);
	   WB.write32(`ADDR_FT_MEMACC_R1, address);
	end

	   wait_fifo_flag(`ADDR_FT_MEMACC_CSR, `FIFO_FULL, 0);

	 WB.write32(`ADDR_FT_MEMACC_R0, 1);
	 WB.write32(`ADDR_FT_MEMACC_R1, data);
	 memacc_prev_addr  = address;
	 
      end

   endtask // UNMATCHED !!

   task ts_fifo_write
     (
      input [27:0] value_r,
      input [3:0] value_f,
      input [4:0] pid,
      input [15:0] fid);
   
      begin
	 
	 while(tsf_wr_full) @(posedge clk);

	 tsf_val_r  <= value_r;
	 tsf_val_f  <= value_f;
	 tsf_pid    <= pid;
	 tsf_fid    <= fid;


	 
	 tsf_wr_req <= 1;
	 @(posedge clk);
	 tsf_wr_req <= 0;

      end   
   endtask // ts_fifo_write

  task ts_fifo_read (    output [27:0] value_r,
			 output [3:0] value_f,
			 output [4:0] pid,
			 output [15:0] fid);

     begin : TS_FIFO_READ_BODY

	reg [31:0] rval;
	
	wait_fifo_flag(`ADDR_FT_TSF_CSR, `FIFO_EMPTY, 0);

	WB.read32(`ADDR_FT_TSF_R0, rval);
	value_f = rval[31:28];
	value_r = rval[27:0];
	
	WB.read32(`ADDR_FT_TSF_R1, rval);
	
	fid = rval[31:16];
	pid = rval[4:0];
	
     end
     
  endtask // ts_fifo_read
   

  
   
   integer i;
   
   integer rd_val_f, rd_val_r, rd_pid, rd_fid;
   
   initial begin
      wait (WB.ready);
      WB.monitor_bus(0);
      WB.verbose(0);
   
      for(i=0;i<10;i=i+1) memacc_write(i, 3*i);


      
      for(i=0;i<5;i=i+1) begin
//	 ts_fifo_read(rd_val_r, rd_val_f, rd_pid, rd_fid);
//	 $display("TS FIFO READ: val_f %d val_r %d pid %d fid %d", rd_val_f, rd_val_r, rd_pid, rd_fid);
	 
      end
	
      end
   
      
   

   // MEMACC FIFO data sink
   always @(memacc_rd_empty)
     memacc_rd_req  <= ~memacc_rd_empty;

   reg memacc_rd_d0  = 0;
   reg [31:0] memacc_addr = 0;
   
   
   always @(posedge clk) begin
      memacc_rd_d0 <= memacc_rd_req;
      if(memacc_rd_d0)  begin
	 if(!memacc_ad_sel) begin
	   $display("MEMACC_SetAddress: %x", memacc_ad);
	    memacc_addr <= memacc_ad;
	 end else begin
	    $display("MEMACC_Write: addr %x data %x", memacc_addr, memacc_ad);
	    memacc_addr <= memacc_addr + 1;
	 end
      end
   end


   // write some data to the timestamping FIFO

   integer j;
   
   initial begin
      wait(WB.ready);

  //    for(j=0;j<5;j=j+1)
//	ts_fifo_write(j, j+10, j+20, j+30);
      
   end
   
   
   
endmodule
