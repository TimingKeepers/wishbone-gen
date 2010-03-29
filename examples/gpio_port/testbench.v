`timescale 1ns/1ps

`include "output/vlog_constants.v"
`include "../common/wishbone_test_master.v"

module main;



   WB_TEST_MASTER WB();
   
   
   wire [31:0] gpio_pins_b;
   reg [31:0] gpio_reg = 32'bz;

   wire clk = WB.wb_clk;
   wire rst = WB.wb_rst;

   
   gpio_port dut(

		 .rst_n_i   (WB.wb_rst),
		 .wb_clk_i  (WB.wb_clk),
		 .wb_addr_i (WB.wb_addr[2:0]),
		 .wb_data_i (WB.wb_data_o),
		 .wb_data_o (WB.wb_data_i),
		 .wb_cyc_i  (WB.wb_cyc),
		 .wb_stb_i  (WB.wb_stb),
		 .wb_we_i   (WB.wb_we),
		 .wb_sel_i  (WB.wb_bwsel),
		 .wb_ack_o  (WB.wb_ack),
		 .gpio_pins_b (gpio_pins_b)
		 );

   assign gpio_pins_b = gpio_reg;

   reg [31:0] data;



   initial begin
      wait (WB.ready);
      
      $display("Set half of the pins to outputs, other half to inputs");
      WB.write32(`ADDR_GPIO_DDR, 32'hffff0000);
		
      #1 $display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);

      $display("Set every even byte to '1'");
      WB.write32(`ADDR_GPIO_SOPR, 32'hff00ff00);
      
      #1 $display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);
 	
      $display("Clear every even bit");
      WB.write32(`ADDR_GPIO_COPR, 32'h55555555);
 	
      #1 $display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);

      $display("Write an arbitrary value");
      WB.write32(`ADDR_GPIO_PDR, 32'hdeadbeef);

      #1 $display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);

      $display("Force something tasty on the GPIO input pins");
      gpio_reg[15:0] = 16'hcafe;

      #1 $display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);
	
      #1000; // wait for a while (sync logic)
      
      WB.read32(`ADDR_GPIO_PSR, data);
      $display("Time for %x!", data[15:0]);

   end

endmodule
