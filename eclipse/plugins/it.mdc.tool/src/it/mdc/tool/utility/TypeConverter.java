package it.mdc.tool.utility;

import net.sf.orcc.ir.Type;

public class TypeConverter {
	
	public static String translateToCParameter(Type typeToTranslate){
		
		if(typeToTranslate.toString().equals("int(size=32)")) {
			return "int32_t";
		} else if(typeToTranslate.toString().equals("uint(size=32)")){
			return "uint32_t";
		}else {
			return "";	
		}
	}
}
