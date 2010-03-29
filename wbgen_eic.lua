-- -*- Mode: LUA; tab-width: 2 -*-

-- wbgen2 - a simple Wishbone slave generator
-- (c) 2010 Tomasz Wlostowski
-- CERN BE-Co-HT
-- LICENSED UNDER GPL v2

-- EIC (tm)(R) = Embedded Interrupt Controller. We need to register a trademark and start to sue people :)
--
-- EIC_IER = interrupt enable reg [passthru]
-- EIC_IDR = interrupt disable reg [passthru]
-- EIC_IMR = interrupt mask reg [rw, load-ext]
-- EIC_ISR = interrupt status reg [rw, reset on write 1]
--

--function gen_eic_regfield_ier_idr(irq)
--local 	= {	["name"] = irq.name;
--						["description"] = "Disable interrupt "..irq.name;
--						["prefix"] = irq.prefix;
--						["type"] = TYPE_BIT;
--					};
--end

function wbgen_generate_eic()

	if(periph.irqcount == 0) then return; end

	local irq_index = 0;
	local irq_triggers = {};

	local reg_idr = { ["__type"] = TYPE_REG; 
										["__blockindex"] = 1000000;								
										["align"] = 8;
										["name"] = "Interrupt disable register";
										["description"] = "Writing 1 disables handling of the interrupt associated with corresponding bit. Writin 0 has no effect.";
										["c_prefix"] = "EIC_IDR";
										["hdl_prefix"] = "EIC_IDR";

										["signals"] = { signal (SLV, periph.irqcount, "eic_idr_int");
																		signal (BIT, 0, "eic_idr_write_int"); };
																		
										["write_code"] = { va("eic_idr_write_int", 1); };
										["ackgen_code"] = { va("eic_idr_write_int", 0); };
										["reset_code_main"] = { va("eic_idr_write_int", 0); };
										["acklen"] = 1;
										["extra_code"] = { va("eic_idr_int", vi("wrdata_reg", periph.irqcount-1, 0)); };
										["no_std_regbank"] = true;

									};

	local reg_ier = { ["__type"] = TYPE_REG; 
										["__blockindex"] = 1000001;
										["align"] = 1;
										["name"] = "Interrupt enable register";
										["description"] = "Writing 1 enables handling of the interrupt associated with corresponding bit. Writin 0 has no effect.";
										["c_prefix"] = "EIC_IER";
										["hdl_prefix"] = "EIC_IER";
										["signals"] = { signal (SLV, periph.irqcount, "eic_ier_int");
																		signal (BIT, 0, "eic_ier_write_int"); };
																		
										["write_code"] = { va("eic_ier_write_int", 1); };
										["ackgen_code"] = { va("eic_ier_write_int", 0); };
										["reset_code_main"] = { va("eic_ier_write_int", 0); };
										["acklen"] = 1;
										["extra_code"] = { va("eic_ier_int", vi("wrdata_reg", periph.irqcount-1, 0)); };
										["no_std_regbank"] = true;
									};

	local reg_isr = { ["__type"] = TYPE_REG; 
										["__blockindex"] = 1000002;
										["align"] = 1;
										["name"] = "Interrupt status register";
										["description"] = "Each bit represents the state of corresponding interrupt. 1 means the interrupt is pending. Writing 1 to a bit clears the corresponding interrupt. Writing 0 has no effect.";
										["c_prefix"] = "EIC_ISR";
										["hdl_prefix"] = "EIC_ISR";
										["signals"] = { signal (SLV, periph.irqcount, "eic_isr_clear_int");
																		signal (SLV, periph.irqcount, "eic_isr_status_int");
																		signal (BIT, 0, "eic_isr_write_int"); };
																		
										["write_code"] = { va("eic_isr_write_int", 1); };
										["read_code"] = { va(vi("rddata_reg", periph.irqcount-1, 0), "eic_isr_status_int"); };
										
										["ackgen_code"] = { va("eic_isr_write_int", 0); };
										["reset_code_main"] = { va("eic_isr_write_int", 0); };
										["acklen"] = 1;
										["extra_code"] = { va("eic_isr_clear_int", vi("wrdata_reg", periph.irqcount-1, 0)); };
										["no_std_regbank"] = true;
									};

	local reg_imr = { ["__type"] = TYPE_REG; 
										["__blockindex"] = 1000003;
										["align"] = 1;
										["name"] = "Interrupt mask register";
										["description"] = "Shows which interrupts are enabled. 1 means that the interrupt associated with the bitfield is enabled";
										["c_prefix"] = "EIC_IMR";
										["hdl_prefix"] = "EIC_IMR";
										["signals"] = { signal (SLV, periph.irqcount, "eic_imr_int"); };
																		
										["read_code"] = { va(vi("rddata_reg", periph.irqcount-1, 0), "eic_imr_int"); };
										
										["acklen"] = 1;
										["no_std_regbank"] = true;
									};


	
	foreach_reg({TYPE_IRQ}, function(irq) 
		irq.index = irq_index;
		irq_index = irq_index + 1;

		table.insert(irq_triggers, { ["index"] = irq.index; ["trigger"] = irq.trigger; });

		fix_prefix(irq);


		local field_isr = {
			["__blockindex"] = irq.index;			
			["__type"] = TYPE_FIELD;
			["type"] = BIT;
			["name"] = irq.name;
			["description"] = "read 1: interrupt '"..irq.name.."' is pending\nread 0: interrupt not pending\nwrite 1: clear interrupt '"..irq.name.."'\nwrite 0: no effect";
			["c_prefix"] = irq.c_prefix;
			["hdl_prefix"] = irq.hdl_prefix;

			["access_bus"] = READ_WRITE;
			["access_dev"] = READ_WRITE;
		};

		local field_ier = {
			["__blockindex"] = irq.index;			
			["__type"] = TYPE_FIELD;
			["type"] = BIT;
			["name"] = irq.name;
			["description"] = "write 1: enable interrupt '"..irq.name.."'\nwrite 0: no effect";
			["c_prefix"] = irq.c_prefix;
			["hdl_prefix"] = irq.hdl_prefix;

			["access_bus"] = WRITE_ONLY;
			["access_dev"] = READ_ONLY;
		};

		local field_idr = {
			["__blockindex"] = irq.index;			
			["__type"] = TYPE_FIELD;
			["type"] = BIT;
			["name"] = irq.name;
			["description"] = "write 1: disable interrupt '"..irq.name.."'\nwrite 0: no effect";
			["c_prefix"] = irq.c_prefix;
			["hdl_prefix"] = irq.hdl_prefix;

			["access_bus"] = WRITE_ONLY;
			["access_dev"] = READ_ONLY;
		};

		local field_imr = {
			["__blockindex"] = irq.index;			
			["__type"] = TYPE_FIELD;
			["type"] = BIT;
			["name"] = irq.name;
			["description"] = "read 1: interrupt '"..irq.name.."' is enabled\nread 0: interrupt '"..irq.name.."' is disabled";
			["c_prefix"] = irq.c_prefix;
			["hdl_prefix"] = irq.hdl_prefix;
			["access"] = ACCESS_RO_WO;

			["access_bus"] = READ_ONLY;
			["access_dev"] = WRITE_ONLY;
		};


	
		table.insert(reg_idr, field_idr);
		table.insert(reg_isr, field_isr);
		table.insert(reg_imr, field_imr);
		table.insert(reg_ier, field_ier);
		
		irq.full_prefix = string.lower("irq_"..irq.hdl_prefix);
		irq.ports = { port(BIT, 0, "in", irq.full_prefix.."_i"); };
	end);


	add_global_signals( {
		signal(SLV, periph.irqcount, "irq_inputs_vector_int");
	});
	
			
-- add the EIC registers to peripheral
	table.insert(periph, reg_idr);
	table.insert(periph, reg_ier);
	table.insert(periph, reg_imr);
	table.insert(periph, reg_isr);
	
	local maps = {	vgm("g_num_interrupts", 	periph.irqcount);
									vpm("clk_i", 							"bus_clock_int");
									vpm("rst_n_i", 						"rst_n_i");
									vpm("irq_i", 							"irq_inputs_vector_int");
									vpm("reg_imr_o",					"eic_imr_int");
									vpm("reg_ier_i",					"eic_ier_int");
									vpm("reg_ier_wr_stb_i",		"eic_ier_write_int");
									vpm("reg_idr_i",					"eic_idr_int");
									vpm("reg_idr_wr_stb_i",		"eic_idr_write_int");
									vpm("reg_isr_o",					"eic_isr_status_int");
									vpm("reg_isr_i",					"eic_isr_clear_int");
									vpm("reg_isr_wr_stb_i",		"eic_isr_write_int");
									vpm("wb_irq_o",						"wb_irq_o");
								};
		
	local last_i;
	
	for i,v in ipairs(irq_triggers)	do
		table_join(maps, { vgm(string.format("g_irq%02x_mode", v.index), v.trigger) });
		last_i = i;
	end

	-- f****ing stupid VHDL :/
	for i=last_i, 31 do 
			table_join(maps, { vgm(string.format("g_irq%02x_mode", i), 0) });
	end
	
	
	
	local irq_unit_code = { vinstance("eic_irq_controller_inst", "wbgen2_eic", maps	); };
	
	foreach_reg({TYPE_IRQ}, function(irq)
														table_join(irq_unit_code, {va(vi("irq_inputs_vector_int", irq.index), irq.full_prefix.."_i")});
													end);
	
	local fake_irq = {
			["__type"] = TYPE_IRQ;
			["no_docu"] = true;
			["name"] = "IRQ_CONTROLLER";
			["prefix"] = "IRQ_CONTROLLER";
			["extra_code"] = irq_unit_code;
	};

	table.insert(periph, fake_irq);		

end
