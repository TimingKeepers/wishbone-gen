`timescale 1ns/1ps

`define wbclk_period 100
`define clk_async_period 71

`include "output/vlog_constants.v"

module main;
   reg clk=1;
   reg clk_async = 1;
   reg rst=0;

   wire [3:0] ones = 'b1111;

   
	 always #(`wbclk_period) clk<=~clk;
   always #(`clk_async_period/2) clk_async <= ~clk_async;

   initial #1000 rst <= 1;

`include "wishbone_stuff.v"

	wire [31:0] gpio_pins_b;
	reg [31:0] gpio_reg = 32'bz;

	gpio_port_async dut(

    .rst_n_i  	(rst),
    .wb_clk_i 	(clk),
    .wb_addr_i  (wb_addr[2:0]),
    .wb_data_i  (wb_data_o),
    .wb_data_o  (wb_data_i),
    .wb_cyc_i  	(wb_cyc),
    .wb_sel_i   (ones),
    .wb_stb_i  	(wb_stb),
    .wb_we_i   	(wb_we),
    .wb_ack_o  	(wb_ack),
		     

		.gpio_clk_i (clk_async),
    .gpio_pins_b (gpio_pins_b)
    );

	assign gpio_pins_b = gpio_reg;


		reg[31:0] data;

		integer i;


   initial begin
   #2001; // wait until the DUT is reset

 		$display("Set half of the pins to outputs, other half to inputs");
 		wb_write(`ADDR_GPIO_DDR, 32'hffff0000);
		
		$display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);
	
		$display("Set every even byte to '1'");
		wb_write(`ADDR_GPIO_SOPR, 32'hff00ff00);
	
		$display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);
 	
		$display("Clear every even bit");
		wb_write(`ADDR_GPIO_COPR, 32'h55555555);
 	
		$display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);
		
		$display("Write an arbitrary value");
		wb_write(`ADDR_GPIO_PDR, 32'hdeadbeef);

		$display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);
		
		$display("Force something tasty on the GPIO input pins");

		gpio_reg[15:0] = 16'hcafe;

		delay_cycles(1);

		$display("Pins state: %b (%x)", gpio_pins_b, gpio_pins_b);
		
		delay_cycles(10); // wait for a while for the sync logic
		
		wb_read(`ADDR_GPIO_PSR, data);
		$display("Time for %x!", data[15:0]);

	end

		



endmodule
