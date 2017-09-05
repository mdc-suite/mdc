/*
 * Copyright (c) 2013, Ecole Polytechnique Fédérale de Lausanne
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice,
 *     this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *   * Neither the name of the Ecole Polytechnique Fédérale de Lausanne nor the names of its
 *     contributors may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
package it.unica.diee.mdc;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;

/**
 * TODO Add description and comments
 * @author 
 *
 */
public class NetworkClockDomainCombiner {

	private class ClockDomainParser {

		private static final String ELM_CLOCK_RATIO = "clockRatio";
		private static final String ELM_DOMAIN = "domain";
		private static final String ELM_ACTOR = "actor";

		public ClockDomainParser(String clockDomainFile,
				Map<String,Set<String>> clockDomains) {

			File inputFile = new File(clockDomainFile);
			Set<String> actorSet = new HashSet<String>();
			String domain = "";
			try {
				InputStream inStream = new FileInputStream(inputFile);
				XMLInputFactory xmlFactory = XMLInputFactory.newInstance();
				try {
					XMLStreamReader reader = xmlFactory
							.createXMLStreamReader(inStream);
					while (reader.hasNext()) {
						reader.next();
						if (reader.getEventType() == XMLStreamReader.START_ELEMENT
								&& reader.getLocalName().equals(ELM_DOMAIN)) {
							domain = reader.getAttributeValue("", ELM_CLOCK_RATIO);
							actorSet = new HashSet<String>();
						} else if (reader.getEventType() == XMLStreamReader.START_ELEMENT
								&& reader.getLocalName().equals(ELM_ACTOR)) {
							String actor = reader.getElementText();
							actorSet.add(actor);
						} else if (reader.getEventType() == XMLStreamReader.END_ELEMENT
								&& reader.getLocalName().equals(ELM_DOMAIN)) {
							clockDomains.put(domain, actorSet);
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

	private Map<String,Set<String>> clockDomains;
	private Map<String,Map<String,Set<String>>> clockDomainMap;
	private Map<String,Map<String,String>> networkVertexMap;

	public NetworkClockDomainCombiner(List<String> clockDomainFileList,
			Map<String,Map<String,String>> networkVertexMap) {
		this.networkVertexMap = networkVertexMap;
		clockDomainMap = new HashMap<String,Map<String,Set<String>>>();
		
		// Parse the Xml File
		for(String clockDomainFile : clockDomainFileList) {
			Map<String,Set<String>> map = new HashMap<String,Set<String>>();
			new ClockDomainParser(clockDomainFile, map);
			clockDomainMap.put(clockDomainFile.split("report_partitioning_")[1].replace(".xml", "")
					.replace(".xml",""),map);			
		}
	}

	public void combineClockDomain() {
				
		clockDomains = new HashMap<String,Set<String>>();
		
		CleanActorNames();
		
		// for each merged network
		for(String network : clockDomainMap.keySet()) {
			
			// if clock domain is empty set the network clock domain as initial configuration
			if(clockDomains.isEmpty()) {
				for(String domain : clockDomainMap.get(network).keySet()) {
					Set<String> actors = new HashSet<String>();
					for(String actor : clockDomainMap.get(network).get(domain)) {
						if(networkVertexMap.get(network).containsKey(actor)) {
							actors.add(networkVertexMap.get(network).get(actor));
						}
					}
					clockDomains.put(domain,actors);
				}
			} else {
				boolean associated = false;
				Map<String,Set<String>> newDomains = new HashMap<String,Set<String>>();
				Map<String,Set<String>> updDomains = new HashMap<String,Set<String>>();
				Map<String,Set<String>> rmvDomains = new HashMap<String,Set<String>>();
				int n=1;
				
				// for each domain in the current network clock domains
				for(String domain : clockDomainMap.get(network).keySet()) {
					// for each actor in this domain
					for(String actor : clockDomainMap.get(network).get(domain)) {
						// for each already set domain
						for(String alreadySetDomain : clockDomains.keySet()) {
							// for each already set actor
							for(String alreadySetActor : clockDomains.get(alreadySetDomain)) {
								// if the current actor is equal to the already set actor
								if(networkVertexMap.get(network).containsKey(actor)) {
									if(networkVertexMap.get(network).get(actor).equals(alreadySetActor)) { 
										// if the domain period is smaller than the domain of the already set actor
										if(Float.parseFloat(domain)<Float.parseFloat(alreadySetDomain)) {
											System.out.println("upd " + actor + " from " + alreadySetDomain + " to " + domain
										+ "(tot " + n + ")");
											n++;
											// remove the already set actor from the already set domain
											//clockDomains.get(alreadySetDomain).remove(alreadySetActor);
											if(rmvDomains.containsKey(alreadySetDomain)) {
												rmvDomains.get(alreadySetDomain).add(alreadySetActor);
											} else {
												Set<String> set = new HashSet<String>();
												set.add(alreadySetActor);
												rmvDomains.put(alreadySetDomain,set);
											}
											// if the current clock domain is already set
											if(clockDomains.containsKey(domain)) {
												// put the actor in the new domain
												//clockDomains.get(domain).add(networkVertexMap.get(network).get(actor));
												if(updDomains.containsKey(domain)) {
													updDomains.get(domain).add(alreadySetActor);
												} else {
													Set<String> set = new HashSet<String>();
													set.add(alreadySetActor);
													updDomains.put(domain,set);
												}
											} else {
												// add a new domain with the current actor
												/*Set<String> set = new HashSet<String>();
												set.add(networkVertexMap.get(network).get(actor));
												clockDomains.put(domain,set);
												*/if(newDomains.containsKey(domain)) {
													newDomains.get(domain).add(alreadySetActor);
												} else {
													Set<String> set = new HashSet<String>();
													set.add(alreadySetActor);
													newDomains.put(domain,set);
												}
											}
										}
										// the actor has been already set
										associated = true;
									}
								}
							}
						}
						
						// Update clock domains
						for(String rmvDomain : rmvDomains.keySet()) {
							clockDomains.get(rmvDomain).removeAll(rmvDomains.get(rmvDomain));
						}
						for(String updDomain : updDomains.keySet()) {
							clockDomains.get(updDomain).addAll(updDomains.get(updDomain));
						}
						for(String newDomain : newDomains.keySet()) {
							Set<String> set = new HashSet<String>();
							set.addAll(newDomains.get(newDomain));
							clockDomains.put(newDomain,set);
						}
						
						// if the actor has not been already set (it is not a shared actor)
						if(!associated) {
							// if the current clock domain is already set
							if(clockDomains.containsKey(domain)) {
								// put the actor in the new domain
								clockDomains.get(domain).add(networkVertexMap.get(network).get(actor));
							} else {
								// add a new domain with the current actor
								Set<String> set = new HashSet<String>();
								set.add(networkVertexMap.get(network).get(actor));
								clockDomains.put(domain,set);
							}
							associated = false;
							newDomains = new HashMap<String,Set<String>>();
							updDomains = new HashMap<String,Set<String>>();
							rmvDomains = new HashMap<String,Set<String>>();
						}
					
					}
				}
			}
			
		}
		
		//System.out.println("combined domains: " + clockDomains);
		
	}
	
	public Map<String,Set<String>> getClockDomains() {
		return clockDomains;
	}

	private void CleanActorNames() {
				
		for(String network : networkVertexMap.keySet()) {
			Map<String,List<Map<String,String>>> domainMap =
					new HashMap<String,List<Map<String,String>>>();
			for(String domain : clockDomainMap.get(network).keySet()) {
				List<Map<String,String>> actorSubs = 
						new ArrayList<Map<String,String>>();
				for(String actor : clockDomainMap.get(network).get(domain)) {
					for(String mappedActor : networkVertexMap.get(network).keySet()) {
						if(actor.contains(mappedActor.toLowerCase())) {
							Map<String,String> actorMap = new HashMap<String,String>();
							actorMap.put(actor, mappedActor);
							actorSubs.add(actorMap);
							
						}
					}
					
				}
				domainMap.put(domain, actorSubs);
			}
			
			for(String domain : domainMap.keySet()) {
				for(Map<String,String> actorMap : domainMap.get(domain)) {
					clockDomainMap.get(network).get(domain).removeAll(actorMap.keySet());
					clockDomainMap.get(network).get(domain).addAll(actorMap.values());
				}
			}
			// TODO \todo possibile problema per le porte che potrebbero generare falsi matching	
			
		}
				
	};
	

}
