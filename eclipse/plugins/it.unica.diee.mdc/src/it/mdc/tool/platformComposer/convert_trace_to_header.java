package it.mdc.tool.platformComposer;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;

import it.mdc.tool.ConfigManager;
import net.sf.orcc.df.Network;
import net.sf.orcc.util.OrccLogger;

public class convert_trace_to_header {

	private BufferedReader reader;
	
	public convert_trace_to_header(String inPath) throws IOException{
		reader = new BufferedReader(new FileReader(new File(inPath)));
	}

	
	public void convert(String outPath, int size) throws IOException {
		
		String s0 = "";
		
		try {
			String nextLine = null;
			int i=0,j=0;
			PrintStream ps = new PrintStream(new FileOutputStream(outPath));
			PrintStream pscbcr = new PrintStream(new FileOutputStream(outPath.replace("Y.h","CbCr.h")));
			
			ps.print("int data["+size+"]={");
			pscbcr.print("int data["+size+"]={");
			
			while((nextLine = reader.readLine()) != null && j<size) {
				
				/*if(!s0.equals("")){
					if(Integer.parseInt(s0)==255 && Integer.parseInt(nextLine)==217) {
						i=size;
						OrccLogger.traceln("EOI");
					}
				}*/
				
				//s0=nextLine.toString();
				if(i<256) {
					ps.print(nextLine.toString() + ",\n");
				} else {
					pscbcr.print(nextLine.toString() + ",\n");
				}
				if(i<383) {
					i++;
				} else {
					i=0;
					j++;
				}
				
			}

			ps.print("}");
			ps.close();
			pscbcr.print("}");
			pscbcr.close();
			
		} catch (FileNotFoundException e) {
			OrccLogger.severeln("File Not Found Exception: " + e.getMessage());
		}
	}
	
}
