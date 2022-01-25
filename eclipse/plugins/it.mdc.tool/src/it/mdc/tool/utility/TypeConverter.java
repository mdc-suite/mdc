package it.mdc.tool.utility;

import net.sf.orcc.ir.Type;

public class TypeConverter {
	
	public static String translateToCParameter(Type typeToTranslate){
		
		if(typeToTranslate.toString().equals("int(size=32)")) {
			return "int32_t";
		} else if(typeToTranslate.toString().equals("int(size=16)")){
			return "int16_t";
		} else if(typeToTranslate.toString().equals("int(size=8)")){
			return "int8_t";
		} else if(typeToTranslate.toString().equals("uint(size=32)")){
			return "uint32_t";
		} else if(typeToTranslate.toString().equals("uint(size=8)")){
			return "uint8_t";
		} else if(typeToTranslate.toString().equals("uint(size=6)")){
			return "uint6_t";
		}else {
			return "";	
		}
	}
}
