package it.mdc.tool.core;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Connection;
import net.sf.orcc.df.Port;
import net.sf.orcc.df.util.DfVisitor;
import net.sf.orcc.util.OrccLogger;

/**
 * TODO \todo Add description and comments
 * @author 
 *
 */
public class NetworkBufferSizeCombiner extends DfVisitor<Void> {

	private class BufferSizeParser {

		private static final String ELM_FIFOSIZE = "fifosSize";
		private static final String ELM_CONNECTION = "connection";
		private static final String ELM_SOURCE = "source";
		private static final String ELM_TARGET = "target";
		private static final String ELM_SOURCE_PORT = "src-port";
		private static final String ELM_TARGET_PORT = "tgt-port";

		private static final String ELM_SIZE = "size";

		public BufferSizeParser(String bufferSizeFile,
				List<XmlConnection> connections) {

			File inputFile = new File(bufferSizeFile);
			try {
				InputStream inStream = new FileInputStream(inputFile);
				XMLInputFactory xmlFactory = XMLInputFactory.newInstance();
				try {
					XMLStreamReader reader = xmlFactory
							.createXMLStreamReader(inStream);
					while (reader.hasNext()) {
						reader.next();
						if (reader.getEventType() == XMLStreamReader.START_ELEMENT
								&& reader.getLocalName().equals(ELM_CONNECTION)) {
							String source = reader.getAttributeValue("",
									ELM_SOURCE);
							String target = reader.getAttributeValue("",
									ELM_TARGET);
							String sourcePort = reader.getAttributeValue("",
									ELM_SOURCE_PORT);
							String targetPort = reader.getAttributeValue("",
									ELM_TARGET_PORT);
							String strSize = reader.getAttributeValue("",
									ELM_SIZE);
							int size = Integer.valueOf(strSize);
							XmlConnection connection = new XmlConnection(
									source, sourcePort, target, targetPort,
									size);
							connections.add(connection);
						} else if (reader.getEventType() == XMLStreamReader.END_ELEMENT
								&& reader.getLocalName().equals(ELM_FIFOSIZE)) {
							break;
						}

					}

				} catch (XMLStreamException e) {
					e.printStackTrace();
				}

			} catch (FileNotFoundException e) {
				e.printStackTrace();
			}
		}

	}

	private class XmlConnection {
		private String source;
		private String sourcePort;
		private String target;
		private String targetPort;
		private int size;

		public XmlConnection(String source, String sourcePort, String target,
				String targetPort, int size) {
			this.source = source;
			this.target = target;
			this.sourcePort = sourcePort;
			this.targetPort = targetPort;
			this.size = size;
		}

		public int getSize() {
			return size;
		}

		public String getSource() {
			return source;
		}

		public String getSourcePort() {
			return sourcePort;
		}

		public String getTarget() {
			return target;
		}

		public String getTargetPort() {
			return targetPort;
		}
	}

	private Map<String,List<XmlConnection>> xmlConnectionsMap;
	private Map<String,Map<String,String>> networkVertexMap;

	public NetworkBufferSizeCombiner(List<String> bufferSizePartitioningFileList,
			Map<String,Map<String,String>> networkVertexMap) {
		this.xmlConnectionsMap = new HashMap<String,List<XmlConnection>>();
		this.networkVertexMap = networkVertexMap;
		// Parse the Xml File
		for(String bufferSizePartitioningFile : bufferSizePartitioningFileList) {
				//OrccLogger.traceln("file " + bufferSizePartitioningFile);
				List<XmlConnection> list = new ArrayList<XmlConnection>();
			new BufferSizeParser(bufferSizePartitioningFile, list);
			for(XmlConnection c : list) {
				//OrccLogger.traceln(c.source + " " + c.sourcePort + " - " + c.target + " " + c.targetPort);
			}
			xmlConnectionsMap.put(bufferSizePartitioningFile.split("buffers_config_")[1]
					.replace(".ybm",""),list);
		}
	}

	@Override
	public Void caseConnection(Connection connection) {

		String source = null;
		String target = null;
		String sourcePort = null;
		String targetPort = null;

		if (connection.getSource().getAdapter(Actor.class) != null) {
			source = connection.getSource().getAdapter(Instance.class).getSimpleName();//.toLowerCase();
			sourcePort = connection.getSourcePort().getName().toUpperCase();
		} else {
			source = connection.getSource().getAdapter(Port.class).getLabel();
			sourcePort = "";
		}
		if (connection.getTarget().getAdapter(Actor.class) != null) {
			target = connection.getTarget().getAdapter(Instance.class).getSimpleName();//.toLowerCase();
			targetPort = connection.getTargetPort().getName().toUpperCase();
		} else {
			target = connection.getTarget().getAdapter(Port.class).getLabel();
			targetPort = "";
		}
		
		int newSize = getConnectionSize(source, target, sourcePort,targetPort);
		connection.setAttribute("bufferSize", Integer.valueOf(newSize));

		return null;
	}

	public int getConnectionSize(String source, String target,
			String sourcePort, String targetPort) {
		
		OrccLogger.traceln(source + " " + sourcePort + " - " + target + " " + targetPort);

		int maxSize = 0;
		
		//CleanActorNames();
		
		String cmpSource="";
		String cmpTarget="";
		
		if(!target.contains("sbox_")) {
			for(String network : xmlConnectionsMap.keySet()) {
				//OrccLogger.traceln("net " + network);
				for(String vertex : networkVertexMap.get(network).keySet()) {
					if(networkVertexMap.get(network).get(vertex).equals(source)) {
						cmpSource = vertex;//networkVertexMap.get(network).get(vertex);//.toLowerCase();
					}
					if(networkVertexMap.get(network).get(vertex).equals(target)) {
						cmpTarget = vertex;//networkVertexMap.get(network).get(vertex);//.toLowerCase();
					}
				}
				//OrccLogger.traceln(cmpSource + " - " + cmpTarget);
				if((source.contains("sbox_")||(cmpSource!="")) && (cmpTarget!="")) {
					//OrccLogger.traceln("a");
					for(XmlConnection connection : xmlConnectionsMap.get(network)) {
						//OrccLogger.traceln("ct " + connection.getTarget());
						if(connection.getSource().contains(cmpSource)|| source.contains("sbox_")||sourcePort=="") {
							if(connection.getTarget().contains(cmpTarget)||targetPort=="") {
								//OrccLogger.traceln("b");
								if (connection.getSourcePort().equals(sourcePort) || source.contains("sbox_")||sourcePort=="") {
									if (connection.getTargetPort().equals(targetPort)||targetPort=="") {
										//OrccLogger.traceln("c");
										int size = connection.getSize();
										//OrccLogger.traceln(" --> " + size);
										if(maxSize < size) {
											maxSize = size;
										}
									}
								}
							}
						}
					}
				}
				cmpSource="";
				cmpTarget="";
			}
		} else {
			maxSize = 1;
		}

		OrccLogger.traceln(" --> " + maxSize);

		return maxSize;
		
	}
	
	private void CleanActorNames() {

		for(String network : networkVertexMap.keySet()) {
			for(XmlConnection connection : xmlConnectionsMap.get(network)) {
				String source = connection.getSource();
				String target = connection.getTarget();
				for(String actor : networkVertexMap.get(network).keySet()) {
					if(source.contains(actor.toLowerCase())) {
						connection.source = actor;
					}
					if(target.contains(actor.toLowerCase())) {
						connection.target = actor;
					}
				}
			}
		}
		
	};

}
