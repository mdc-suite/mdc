package it.unica.diee.mdc.utility;

import java.util.Map;
import java.util.HashMap;
import java.io.File;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;


public class NlToXdfParser {
	
	private Map<String,String> variables;
	
	private File input;
	private File output;
	
	private FileReader fileReader;
	private FileWriter fileWriter;
	
	private BufferedReader reader;

	private String memoryInstance;
	private boolean hasControl;
	
	public NlToXdfParser(String inputPath, String outputPath) throws IOException {
		input = new File(inputPath);
		fileReader = new FileReader(input);
		reader = new BufferedReader(fileReader);
		output = new File(outputPath);
		fileWriter = new FileWriter(output);
		variables = new HashMap<String,String>();
	}
	
	private void setInput(String inputPath) throws IOException {
		input = new File(inputPath);
		fileReader = new FileReader(input);
		reader = new BufferedReader(fileReader);
	}
	
	private void setOutput(String outputPath) throws IOException {
		output = new File(outputPath);
		fileWriter = new FileWriter(output);	
	}
	
	private void resetVariables() {
		variables = new HashMap<String,String>();
	}
	
	public void writeMultipleNets(String netList, String inPath, String outPath) throws IOException {
		BufferedReader br = new BufferedReader(new FileReader(new File(netList)));
		String nextNet = null;
		while((nextNet = br.readLine()) != null) {
			System.out.println("\nParsing net " + nextNet);
			setInput(inPath + nextNet);
			setOutput(outPath + nextNet.split("\\.")[0] + ".xdf");
			resetVariables();
			writeXdf();
		}
		
		br.close();
	}
	
	public void writeXdf() throws IOException {
		
		// write xdf file header
		fileWriter.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
		
		// read cycle
		String inputString = reader.readLine();
		hasControl = false;
		Boolean named = false;
		Boolean savingVariables = false; 
		Boolean printingEntities = false;
		Boolean printingConnections = false;
		
		while(inputString != null){
			
			System.out.println(inputString);
			
			if (savingVariables && !inputString.equals("") && inputString.contains("=")) {
				saveVariables(inputString);
			} else if (printingEntities && !inputString.equals("") && inputString.contains("=")) {
				writeEntities(inputString); 	
			} else if (printingConnections && !inputString.equals("") && inputString.contains("-")) {
				writeConnections(inputString);
			}
						
			if(inputString.contains("network") && !named) {
				writeNetworkName(inputString);
				named = true;
			} else if(inputString.contains("var")) {
				savingVariables = true;
			} else if (inputString.contains("entities")) {
				printingEntities = true;
				savingVariables = false;
			} else if (inputString.contains("structure")) {
				printingConnections = true;
				printingEntities = false;
			} 
			
			inputString = reader.readLine();
		}
		
		if(hasControl)
			writeMemoryConnections();
			
		fileWriter.write("\n</XDF>");
		fileWriter.close();
		reader.close();
			
	}

	private void writeNetworkName(String inputString) throws IOException {

		// read name of the network
		String name = inputString.split("\\(")[0].split(" ")[1];
		
		// write name of the network
		fileWriter.write("\n<XDF name=\"" + name + "\">");

		writeNetworkPorts(inputString.split("\\)")[1]);
		
	}

	private void writeNetworkPorts(String inputString) throws IOException {
		
		String inputPorts = inputString.split("==>")[0];
		String outputPorts = inputString.split("==>")[1];
		
		// write inputs
		for (String inputPort : inputPorts.split(",")) {
			if (inputPort.contains(" ")) {
				fileWriter.write("\n\t<Port kind=\"Input\" name=\"" + inputPort.split(" ")[1] +"\">");
			} else {
				fileWriter.write("\n\t<Port kind=\"Input\" name=\"" + inputPort +"\">");
			}
			fileWriter.write("\n\t\t<Type name=\"int\">");
			fileWriter.write("\n\t\t\t<Entry kind=\"Expr\" name=\"size\">");
			fileWriter.write("\n\t\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\" value=\"32\"/>");
			fileWriter.write("\n\t\t\t </Entry>" +
							 "\n\t\t</Type>" +
							 "\n\t</Port>");
		}
		
		// write outputs
		for (String outputPort : outputPorts.split(",")) {
			if (outputPort.contains(" ")) {
				fileWriter.write("\n\t<Port kind=\"Output\" name=\"" + outputPort.split(" ")[1].split(":")[0] +"\">");
			} else {
				fileWriter.write("\n\t<Port kind=\"Output\" name=\"" + outputPort.split(":")[0] +"\">");
			}
			fileWriter.write("\n\t\t<Type name=\"int\">");
			fileWriter.write("\n\t\t\t<Entry kind=\"Expr\" name=\"size\">");
			fileWriter.write("\n\t\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\" value=\"32\"/>");
			fileWriter.write("\n\t\t\t </Entry>" +
							 "\n\t\t</Type>" +
							 "\n\t</Port>");
		}
	}

	private void saveVariables(String inputString) {
		
		String name = inputString.split("=")[0];
		String value = inputString.split("=")[1].split(";")[0];
		
		if(name.contains(" "))
			for(String n : name.split(" "))
				if(!n.equals("")) {
					name = n;
					break;
				}
		
		variables.put(name, value);
		
		System.out.println("\nVariables: " + variables);
		
	}
	
	private void writeEntities(String inputString) throws IOException {

		String instance = inputString.split("\\(")[0];
		String parameters = "";
		if(inputString.split("\\(").length!=2) {
			for (int i=1; i<inputString.split("\\(").length; i++)
				parameters += inputString.split("\\(")[i];
		} else { 
			parameters = inputString.split("\\(")[1];
		}
		System.out.println("\nParameters: " + parameters);
		parameters = parameters.split(";")[0];
		String temp = parameters;
		parameters="";
		if(temp.split("\\)").length<=1) {
			parameters=temp.split("\\)")[0];
		} else {
			for(int i=0;i<temp.split("\\)").length;i++)
				parameters+=temp.split("\\)")[i];
		}
		System.out.println("\nParameters: " + parameters);
		
		String instName = null;
		
		// write instance
		if (instance.split("=")[0].contains(" ")) {
			for (String inst : instance.split("=")[0].split(" "))
				if(!inst.equals("")) {
					instName = inst;
					break;
				}
		} else {
			instName =  instance.split("=")[0];
		}
		
		String instClass = null;
		
		if (instance.split("=")[1].contains(" ")) {
			instClass = instance.split("=")[1].split(" ")[1];
		} else {
			instClass = instance.split("=")[1];
		}
		
		/*if(instClass.contains("memory")) {
			writeMemory(instClass,parameters);
			memoryInstance = instName;
			hasControl = true;
		} else {*/
			fileWriter.write("\n\t<Instance id=\"" + instName + "\">");
			fileWriter.write("\n\t\t<Class name=\"alba.cal." + instClass + "\"/>");
			for(int i=0; i < parameters.split(",").length; i++) {
				String parameter = parameters.split(",")[i];
				fileWriter.write("\n\t\t<Parameter name=\"" + parameter.split("=")[0] + "\">");
				if(variables.containsKey(parameter.split("=")[1])) {
					fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\" value=\"" + variables.get(parameter.split("=")[1]) + "\"/>");
				} else {
					fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\" value=\"" + parameter.split("=")[1] + "\"/>");
				}
				fileWriter.write("\n\t\t</Parameter>");
			}
			fileWriter.write("\n\t</Instance>");
		//}
		
	}	
	
	/*private void writeMemory(String instClass, String parameters) throws IOException {
		
		String controlName = null;
		
		if(instClass.equals("memory")) {
			controlName = "control_3out_1par";
		} else if (instClass.equals("memory_1x2")) {
			controlName = "control_2out_3par";
		} else if (instClass.equals("memory_1x8")) {
			controlName = "control_8out_0par";
		} else if (instClass.equals("memory_1x1")) {
			controlName = "control_1out_0par";
		} else if (instClass.equals("memory_1x1b")) {
			controlName = "control_1out_5par";
		}
		
		fileWriter.write("\n\t<Instance id=\"control\">");
		fileWriter.write("\n\t\t<Class name=\"alba.cal." + controlName + "\"/>");
		for(int i=0; i < parameters.split(",").length; i++) {
			String parameter  = parameters.split(",")[i];
			fileWriter.write("\n\t\t<Parameter name=\"" + parameter.split("=")[0] + "\">");
			if(variables.containsKey(parameter.split("=")[1])) {
				fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\" value=\"" + variables.get(parameter.split("=")[1]) + "\"/>");
			} else {
				fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\" value=\"" + parameter.split("=")[1] + "\"/>");
			}
			fileWriter.write("\n\t\t</Parameter>");
		}
		fileWriter.write("\n\t</Instance>");
		
		fileWriter.write("\n\t<Instance id=\"RAM\">");
		fileWriter.write("\n\t\t<Class name=\"alba.cal.memory\"/>");
		for(int i=0; i < parameters.split(",").length; i++) {
			String parameter = parameters.split(",")[i];
			if(parameter.split("=")[0].equals("DATA_SIZE")) {
				fileWriter.write("\n\t\t<Parameter name=\"WORD_SIZE\">");
			} else {
				fileWriter.write("\n\t\t<Parameter name=\"" + parameter.split("=")[0] + "\">");
			}
			if(variables.containsKey(parameter.split("=")[1])) {
				fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\" value=\"" + variables.get(parameter.split("=")[1]) + "\"/>");
			} else {
				fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\" value=\"" + parameter.split("=")[1] + "\"/>");
			}
			fileWriter.write("\n\t\t</Parameter>");
		}
		fileWriter.write("\n\t</Instance>");
		
	}*/

	private void writeConnections(String inputString) throws IOException {
		
		String source = inputString.split("-->")[0];
		String target = inputString.split("-->")[1];
		String sourcePort;
		String targetPort;
		String bufferSize = inputString.split("\\{")[1].split("\\}")[0];
		String bufferSizeValue = resolveValue(bufferSize.split("=")[1].split(";")[0]);
		
		if(bufferSizeValue.equals("3*32")) {
			bufferSizeValue = "96";
		} else if (bufferSizeValue.equals("2*32+2*16")) {
			bufferSizeValue = "96";
		}
		
		// assigning source port
		if (source.contains(".")) {
			sourcePort = source.split("\\.")[1];
			source = source.split("\\.")[0]; 
		} else {
			sourcePort = source;
			source = "";
		}	
		
		// assigning target port
		if (target.contains(".")) {
			targetPort = target.split("\\.")[1].split("\\{")[0];
			target = target.split("\\.")[0];
		} else {
			targetPort = target.split("\\{")[0];
			target = "";
		}
		
		if(target.contains(" "))
			for(String tgt : target.split(" "))
				if(!tgt.equals("")) {
					target = tgt;
					break;
				}
		
		if(targetPort.contains(" "))
			for(String tgtPort : targetPort.split(" "))
				if(!tgtPort.equals("")) {
					targetPort = tgtPort;
					break;
				}
		
		if(sourcePort.contains(" "))
			sourcePort = sourcePort.split(" ")[0];
		
		if(source.equals(memoryInstance) && hasControl)
			source = "control";
		
		if(target.equals(memoryInstance) && hasControl) {
			target = "control";
			targetPort = "in2";
		}
		
		fileWriter.write("\n\t<Connection dst=\"" + target +
									"\" dst-port=\"" + targetPort +
										 "\" src=\"" + source +
									"\" src-port=\"" + sourcePort +
									"\">");
		fileWriter.write("\n\t\t<Attribute kind=\"Value\" name=\"bufferSize\">");
		fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\"" +
				" value=\"" + bufferSizeValue + "\"/>");
		fileWriter.write("\n\t\t</Attribute>");
		fileWriter.write("\n\t</Connection>");
	}
	
	private String resolveValue(String string) {
		System.out.println("\ninput string: " + string);
		String result="";
		if (string.contains("+")) {
			result = resolveValue(string.split("\\+")[0]);
			for(int i=1; i<string.split("\\+").length; i++)
				result += "+" +  resolveValue(string.split("\\+")[i]);
		} else if (string.contains("*")) {
			result = resolveValue(string.split("\\*")[0]);
			for(int i=1; i<string.split("\\*").length; i++) 
				result += "*" + resolveValue(string.split("\\*")[i]);
		} else if (variables.containsKey(string)) {
			result = variables.get(string);
		} else {
			result = string;
		}
		System.out.println("\nresult string: " + result);
		return result;
	}

	private void writeMemoryConnections() throws IOException {
		fileWriter.write("\n\t<Connection dst=\"RAM\" dst-port=\"data_in" +
					  "\" src=\"\" src-port=\"in1\">");
		fileWriter.write("\n\t\t<Attribute kind=\"Value\" name=\"bufferSize\">");
		fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\"" +
				" value=\"" + variables.get("DATA_SIZE") + "\"/>");
		fileWriter.write("\n\t\t</Attribute>");
		fileWriter.write("\n\t</Connection>");
		
		fileWriter.write("\n\t<Connection dst=\"RAM\" dst-port=\"address_in" +
				  "\" src=\"control\" src-port=\"addr_in\">");
		fileWriter.write("\n\t\t<Attribute kind=\"Value\" name=\"bufferSize\">");
		fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\"" +
				" value=\"" + 10 + "\"/>");
		fileWriter.write("\n\t\t</Attribute>");
		fileWriter.write("\n\t</Connection>");
		
		fileWriter.write("\n\t<Connection dst=\"RAM\" dst-port=\"address_out" +
				  "\" src=\"control\" src-port=\"addr_out\">");
		fileWriter.write("\n\t\t<Attribute kind=\"Value\" name=\"bufferSize\">");
		fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\"" +
				" value=\"" + 10 + "\"/>");
		fileWriter.write("\n\t\t</Attribute>");
		fileWriter.write("\n\t</Connection>");
		
		fileWriter.write("\n\t<Connection dst=\"control\" dst-port=\"in1" +
				  "\" src=\"RAM\" src-port=\"data_out\">");
		fileWriter.write("\n\t\t<Attribute kind=\"Value\" name=\"bufferSize\">");
		fileWriter.write("\n\t\t\t<Expr kind=\"Literal\" literal-kind=\"Integer\"" +
				" value=\"" + variables.get("DATA_SIZE") + "\"/>");
		fileWriter.write("\n\t\t</Attribute>");
		fileWriter.write("\n\t</Connection>");
		
	}
	
}