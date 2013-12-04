-- -*- Mode: LUA; tab-width: 2 -*-

-- some constants --

-- DEBUG MACROS
VERBOSE_DEBUG = 0;

-- bus properties
DATA_BUS_WIDTH = 32;
SYNC_CHAIN_LENGTH = 3;

-- constant definitions (block types)
TYPE_PERIPH = 1;
TYPE_REG = 2;
TYPE_FIELD = 3;
TYPE_FIFO = 4;
TYPE_ENUM = 5;
TYPE_RAM = 6;
TYPE_IRQ = 7;

ALL_REG_TYPES = {TYPE_REG, TYPE_RAM, TYPE_FIFO, TYPE_IRQ};

-- FIFO register flags
FIFO_FULL = 0x1;
FIFO_EMPTY = 0x2;
FIFO_CLEAR = 0x10;
FIFO_COUNT = 0x20;

-- FIFO directions

BUS_TO_CORE = 1;
CORE_TO_BUS = 2;

-- field access flags
READ_ONLY = 0x1;
READ_WRITE = 0x2;
WRITE_ONLY = 0x4;
SET_ON_WRITE = 0x8;
RESET_ON_WRITE = 0x10;

-- field types
MONOSTABLE = 0x1;
BIT = 0x2;
SLV = 0x4;
SIGNED = 0x8;
UNSIGNED = 0x10;
ENUM = 0x20;
PASS_THROUGH = 0x40;
INTEGER = 0x80;
EXPRESSION = 0x100;
UNDEFINED = 0x200;
CONSTANT = 0x400;

-- reg LOAD types
LOAD_INT = 1;
LOAD_EXT = 2;

-- access shorcuts
ACC_RO_WO = 1;
ACC_WO_RO = 2;
ACC_RW_RW = 3;
ACC_RW_RO = 4;

FROM_WB = 1;
TO_WB = 2;

-- IRQ triggers
EDGE_RISING = 0;
EDGE_FALLING = 1;
LEVEL_0 = 2;
LEVEL_1 = 3;

-- constructors for WB-file blocks
function peripheral(x) 	x['__type']=TYPE_PERIPH; periph = x; 	return x; end
function reg(x) 				x['__type']=TYPE_REG; 								return x; end
function field(x) 			x['__type']=TYPE_FIELD; 							return x; end
function fifo_reg(x) 		x['__type']=TYPE_FIFO;								return x; end
function ram(x) 				x['__type']=TYPE_RAM;  								return x; end
function enum(x) 				x['__type']=TYPE_ENUM; 								return x;	end
function irq(x) 				x['__type']=TYPE_IRQ; 								return x; end


function dbg(...)
	 if(VERBOSE_DEBUG ~= 0) then print(arg); end
end

-- function chceks if argument p is nil and if it is, throws fatal error message s
function chk_nil(p,s)
	if(p == nil) then
		die(s.." expected.");
	end
	return p;
end

-- function calculates necessary amount of bits for a U2-encoded number of specified range.
function range2bits(range)
  local min = range[1];
  local max = range[2];
  local msize;
    
	if(math.abs(min) > math.abs(max)) then
		msize = math.abs(min);
  else
		msize = math.abs(max);
  end
    
  local logsize = math.ceil(math.log(msize) / math.log(2));

  if(min < 0) then
		logsize = logsize + 1;
  end

  return logsize;
end

-- function checks and calculates size of field "field" in register "reg"
function calc_size(field, reg)
-- monostable or bit-field? default size to 1 if not specified
	
    if(field.type == MONOSTABLE or field.type == BIT) then
			field.size = 1;
    elseif (field.type == SLV or field.type == PASS_THROUGH) then
-- SLV fields must have defined size
			if(field.size == nil)  then
		    die("no size declared for SLV-type field '".. field.name.."'");
			end
    elseif (field.type == SIGNED or field.type == UNSIGNED) then
-- signed/unsigned fields must have defined either size or range.
			if(field.range == nil and field.size == nil)  then
		    die("neither range nor size declared for SIGNED/UNSIGNED-type field '".. field.name.."'");
			end

-- no size specified for signed/unsigned field? - calculate it from range attribute
			if(field.size == nil) then
				local nbits = range2bits(field.range);

-- oops, wrong range?		
				if(nbits == nil) then
	  	  	die("misdeclared range for SIGNED/UNSIGNED-type field '".. field.name.."'");
				end
				field.size = nbits;
			end    

-- no enums yet
    elseif(field.type == ENUM) then
			die("ENUM-type fields are not yet supported. Sorry :(");    
    end
    
-- calculate the total size (in bits) of the register
    reg.total_size = reg.total_size + field.size;
end

-- iterates for all registers which type is in "accecepted_types", executing function "func" for each register
function foreach_reg(accepted_types, func, p)
	if(p == nil) then 
		p = periph;
	end
	
	for i,v in ipairs(p) do
	  if(type(v) == 'table') then
	  	if(v.__type ~= nil and (match(v.__type, accepted_types))) then
			  func(v);
			end
    end
	end
end

-- iterates for all fields in the peripheral (e.g. all the fields withing REG or FIFO blocks). Function "func" is executed for each field.
function foreach_field(func)
	foreach_reg ({TYPE_REG, TYPE_FIFO}, function(reg)
    for j,field in ipairs(reg) do
	    if (type(field) == 'table' and field.__type == TYPE_FIELD) then
				func(field, reg, periph);
	    end
    end
  end);
end

-- iterates for all fields of register "reg". Function "func" is executed for each field.
function foreach_subfield(reg, func)
  for j,field in ipairs(reg) do
		if (type(field) == 'table' and field.__type == TYPE_FIELD) then
			func(field, reg);
		end
  end
end

-- calculates aligned offset of field "field" closest to value of "offset".
function align(field, offset)
  local a;

-- no alignment defined? just assume it's 1
  if(field.align == nil) then a=1; else a=field.align; end 

  local newofs;

	if (offset == 0 and field.align ~= nil) then
		newofs = field.align;
	else
		newofs = a  * math.floor((offset + a - 1) / a);
	end
		
-- calculate the aligned offset    

	print("Align  ", field.name, field.align, offset, newofs);

  return newofs;
end


-- calculates offsets of field "field" in register "reg";
function calc_field_offset(field, reg)

-- align the field offset next to the current offset in the reg
	 local ofs = reg.current_offset;


-- FIFOs can span multiple I/O registers.
	 if (reg.__type == TYPE_FIFO) then

			local ofs_new = align(field, ofs);

			if((ofs_new % DATA_BUS_WIDTH) + field.size > DATA_BUS_WIDTH) then 
				 field.align = DATA_BUS_WIDTH;
				 ofs = align(field, ofs);
			else
				 ofs = ofs_new;
			end

			reg.current_offset = ofs + field.size;
			field.offset = ofs;

	 else

			ofs = align(field, ofs);
	 
-- update the current offset
			reg.current_offset = ofs + field.size;
			field.offset = ofs;
	 end

-- update the "unaligned" offset - for FIFOs
	 field.offset_unaligned = reg.current_offset_unaligned;
	 reg.current_offset_unaligned = reg.current_offset_unaligned + field.size;
		
		


-- oops, we have too many fields (the total size exceeds the data bus width)    
    if( reg.__type == TYPE_REG and reg.current_offset > DATA_BUS_WIDTH ) then
			 die ("Total size of register '"..reg.name.."' ("..reg.current_offset..") exceeds data bus width ("..DATA_BUS_WIDTH..")");
		end
end

-- calculate the number of fields in the register
function calc_num_fields(field, reg)
		if(reg.num_fields == nil) then reg.num_fields = 0; end
		reg.num_fields = reg.num_fields + 1;
end

-- commits a suicide with error message "s"
function die(s)
    print ("Error: "..s);
    os.exit(-1);
end


-- checks if value "var" is present in table "values".
function match(var, values)
	local i,v;
    for i,v in pairs(values) do
			if(var==v) then return true; end
    end
  return false;
 end

function inset(var, set)
	 for i,v in ipairs(set) do if(var == v) then return true; end end
	 return false;
end

-- simulates C statement: a = cond ? x : y -> a = csel(cond, x, y);
function csel(cond, tr, fl)
	if(cond) then
		return tr;
  else
		return fl;
  end
end

function check_field_types(field)
	if(field.type == nil) then
			die("no type declared for field: "..field.name);
		end
end

function check_obj_names_prefixes(obj)
	if(obj.name == nil) then
			die("no name declared for object: "..obj.size);
		end
end

function fix_prefix(obj)
	if(obj.c_prefix == nil or obj.hdl_prefix==nil) then
	    if(obj.prefix == nil and obj.__type ~= TYPE_FIELD) then 
				die ("No C/HDL prefix nor default prefix defined for field/reg/peripheral '"..obj.name.."'");
	    end
	    obj.c_prefix = obj.prefix;
	    obj.hdl_prefix = obj.prefix;	
	    return obj;
	end
    return obj;
end

function default_access(field, mytype, acc_bus, acc_dev)
    if(field.type == mytype) then
        if(field.access_bus == nil) then
    	    field.access_bus = acc_bus;
	end
    
        if(field.access_dev == nil) then
	    field.access_dev = acc_dev;
	end
    end
end

function fix_access(field, reg)

    if(reg.__type == TYPE_REG) then
    
	default_access(field, BIT, READ_WRITE, READ_ONLY);
	default_access(field, SLV, READ_WRITE, READ_ONLY);
	default_access(field, SIGNED, READ_WRITE, READ_ONLY);
	default_access(field, UNSIGNED, READ_WRITE, READ_ONLY);
	default_access(field, MONOSTABLE, WRITE_ONLY, READ_ONLY);
	default_access(field, ENUM, READ_WRITE, READ_ONLY);
	default_access(field, PASS_THROUGH, WRITE_ONLY, READ_ONLY);
	default_access(field, CONSTANT, READ_ONLY, WRITE_ONLY);
		
	if(field.access ~= nil) then
	    return;
	end
	
	if(field.access_bus == READ_ONLY and field.access_dev == WRITE_ONLY) then
	    field.access = ACC_RO_WO;
	elseif (field.access_bus == WRITE_ONLY and field.access_dev == READ_ONLY) then
	    field.access = ACC_WO_RO;
	elseif (field.access_bus == READ_WRITE and field.access_dev == READ_WRITE) then
	    field.access = ACC_RW_RW;
	elseif (field.access_bus == READ_WRITE and field.access_dev == READ_ONLY) then
	    field.access = ACC_RW_RO;
	else
	    die ("Illegal access flags combination for field '"..field.name.."' in register '"..reg.name.."'");
	end 
	
    end
end

function check_max_size(reg)
    if(reg.total_size > DATA_BUS_WIDTH and reg.__type == TYPE_REG) then 
        die ("register ".. reg.name.. " size exceeds data bus witdh (".. DATA_BUS_WIDTH.. " bits)"); 
    end
end



all_regs_size = 0;
max_ram_addr_bits = 0;
block_bits = 0;
num_rams = 0;

function log2 (x)
    return math.floor(math.log(x) / math.log(2));
end

function log2up (x)
    return math.ceil(math.log(x) / math.log(2));
end

function is_power_of_2(x)
    for i=1,24 do
	if(x == math.pow(2, i)) then return true; end
    end
    return false;
end

function calc_address_sizes(reg)
-- for ordinary registers - just count them
	if(reg.__type == TYPE_REG) then
		all_regs_size = align(reg, all_regs_size) + 1;
-- for FIFOS: 
-- size of all FIFO fields (rounded up to multiple of 32 bits) + 1 extra FIFO control register
--  elseif (reg.__type == TYPE_FIFO) then
--		fifo_size = math.floor((reg.total_size + DATA_BUS_WIDTH - 1) / DATA_BUS_WIDTH) + 1;
--		all_regs_size = all_regs_size + fifo_size;
--		reg.num_fifo_regs = fifo_size;
-- for RAMs:
  elseif (reg.__type == TYPE_RAM) then
		if(not is_power_of_2(reg.size)) then die ("RAM '"..reg.name.."': memory size must be a power of 2"); end

		if (reg.wrap_bits == nil) then
	    reg.wrap_bits = 0;
		end
	
		reg.addr_bits = log2(reg.size * math.pow(2, reg.wrap_bits));
	
		if(max_ram_addr_bits < reg.addr_bits) then
	    max_ram_addr_bits = reg.addr_bits;
		end

		if(reg.width > DATA_BUS_WIDTH) then
	    die("RAM '"..reg.name.."' data width exceeds WB data bus width");
		end
	
		reg.select_bits = csel(periph.regcount+periph.fifocount == 0, num_rams, num_rams + 1);
		num_rams = num_rams + 1;

    end 
  regbank_address_bits = log2up (all_regs_size);
end



function assign_addresses()

    local block_bits = math.max(max_ram_addr_bits, log2up(all_regs_size));
    
    local num_blocks = num_rams;
    local i = 0;
    if(all_regs_size > 0) then
	num_blocks = num_blocks + 1;
    end

    local select_bits = log2up (num_blocks);
    
--    print("Total bits per block: "..block_bits..", select bits: "..select_bits);
    
    foreach_reg({TYPE_REG, TYPE_FIFO}, function(reg) 
			if(reg.__type==TYPE_REG) then
		    reg.base = align(reg, i);
		    i=reg.base+1;
--			elseif(reg.__type == TYPE_FIFO) then
	--	    reg.base = i;
		--    i=i+reg.num_fifo_regs;
			end
    end );
    
    address_bus_width = block_bits + select_bits;
    address_bus_select_bits = select_bits;
end

function find_max(table, field)
	local mval = 0;
	local i,v;
	for i,v in pairs(table) do if(type(v) == 'table' and v[field]~=nil and v[field] > mval) then mval = v[field]; end end
	return mval;
end



function table_join(table_out, table_in)
    local i,v;
    
    if(table_in == nil) then return; end

    for i,v in ipairs(table_in) do
			 table.insert(table_out, v);
    end
end

function tree_2_table(entry)
	local tab = {};

    foreach_reg({TYPE_REG, TYPE_RAM, TYPE_FIFO, TYPE_IRQ}, function(reg)
			if(reg[entry] ~= nil) then
		    if(type(reg[entry]) == 'table') then 
					table_join(tab, reg[entry]);
		    else
					table.insert(tab, reg[entry]);
		    end
			end
		
			foreach_subfield(reg, function(field, reg) 
		    if(field[entry] ~= nil) then 
			    if(type(field[entry]) == 'table') then 
						table_join(tab, field[entry]);
			    else
						table.insert(tab, field[entry]);
			    end
		    end
			end);
    end);
	 
	 return tab;
end



function remove_duplicates(t)
  function count_entries(tab, entry)
 	  local i,v,cnt;
 	  cnt=0;
 	  for i,v in ipairs(tab) do if(v == entry) then cnt = cnt+1; end end
 	  return cnt;
  end

 
  local t2={};
 
	for i,v in ipairs(t) do
	 local cnt = count_entries(t2, v);
	 if(cnt == 0) then
		table.insert(t2,v);
		end 
	end
 return t2;
end

                                                                                                                      

function wbgen_count_subblocks()
  local ramcount = 0;
  local fifocount = 0;
  local regcount = 0;
  local irqcount = 0;

  foreach_reg({TYPE_RAM}, function(reg) ramcount = ramcount + 1; end);
  foreach_reg({TYPE_REG}, function(reg) regcount = regcount + 1; end);
  foreach_reg({TYPE_FIFO}, function(reg) fifocount = fifocount + 1; end);
  foreach_reg({TYPE_IRQ}, function(reg) irqcount = irqcount + 1; end);
      
	periph.ramcount = ramcount;
  periph.fifocount = fifocount;
  periph.regcount = regcount;
  periph.irqcount = irqcount;
  
  if(ramcount + fifocount + regcount + irqcount == 0) then
  	die("Can't generate an empty peripheral. Define some regs, RAMs, FIFOs or IRQs, please...");
  end
end



function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
