/*
 * Copyright (c) 2012, IETR/INSA of Rennes
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
 *   * Neither the name of the IETR/INSA of Rennes nor the names of its
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

package net.sf.orcc.backends.c.preesm

import net.sf.orcc.backends.c.CTemplate
import net.sf.orcc.df.Argument
import net.sf.orcc.df.Connection
import net.sf.orcc.df.Instance
import net.sf.orcc.df.Network
import net.sf.orcc.moc.CSDFMoC
import net.sf.orcc.util.OrccLogger

/**
 * Generate network as graphml file
 * 
 * @author Antoine Lorence
 */
class NetworkPrinter extends CTemplate {

	var Network network

	def setNetwork(Network network) {
		this.network = network
	}

	def getSizesCSV() {
		var keys = newArrayList("i64", "i32", "i16", "i8")
		var values = newArrayList(8, 4, 2, 1)
		for(instance : network.children.filter(typeof(Instance))) {
			if(!instance.getActor.stateVars.empty) {
				keys.add('''«instance.getActor.simpleName»_stateVars''')
				val structSize = instance.getActor.stateVars.fold(0, [total, v | total + v.type.sizeInBits])
				if(structSize % 8 == 0) {
					values.add(structSize / 8)
				} else {
					OrccLogger::warnln("State variables seems to have not been resized.")
					values.add((structSize / 8) + 1)
				}
			}
		}
		'''
			«keys.join(",")»
			«values.join(",")»
		'''
	}

	def getNetworkContent() '''
		<?xml version="1.0" encoding="UTF-8"?>
			<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
		    <key attr.name="graph_desc" attr.type="string" for="node" id="graph_desc"/>
		    <key attr.name="name" attr.type="string" for="graph" id="name"/>
		    <key attr.name="name" attr.type="string" for="node" id="name"/>
		    <key attr.name="arguments" attr.type="string" for="node" id="arguments"/>
		    <key attr.name="parameters" attr.type="string" for="graph" id="parameters"/>
		    <key attr.name="variables" attr.type="string" for="graph" id="variables"/>
		    <key attr.name="edge_prod" attr.type="string" for="edge" id="edge_prod">
		        <desc>org.sdf4j.model.sdf.types.SDFNumericalEdgePropertyTypeFactory</desc>
		    </key>
		    <key attr.name="edge_delay" attr.type="string" for="edge" id="edge_delay">
		        <desc>org.sdf4j.model.sdf.types.SDFNumericalEdgePropertyTypeFactory</desc>
		    </key>
		    <key attr.name="edge_cons" attr.type="string" for="edge" id="edge_cons">
		        <desc>org.sdf4j.model.sdf.types.SDFNumericalEdgePropertyTypeFactory</desc>
		    </key>
		    <key attr.name="data_type" attr.type="string" for="edge" id="data_type">
		        <desc>org.sdf4j.model.sdf.types.SDFTextualEdgePropertyTypeFactory</desc>
		    </key>
		    <graph edgedefault="directed">
			    «IF network.simpleName != null»
			    	<data key="name">«network.simpleName»</data>
			    «ELSE»
			        <data key="name" />
			    «ENDIF»
			    «IF network.parameters.empty»
			    	<data key="parameters"/>
			    «ELSE»
			    	<data key="parameters">
			    		«FOR parameter : network.parameters»
			    			<parameter name="«parameter.name»"/>
			    		«ENDFOR»
			    	</data>
			    «ENDIF»
				«IF network.variables.empty»
					<data key="variables"/>
			    «ELSE»
					<data key="variables">
						«FOR variable : network.variables»
							<variable name="«variable.name»" value="«variable.initialValue.doSwitch»"/>
						«ENDFOR»
					</data>
			    «ENDIF»
			    «FOR instance : network.children.filter(typeof(Instance))»
			    	«instance.print»
			    «ENDFOR»
			    «FOR conn : network.connections»
			    	«conn.print»
			    «ENDFOR»
		    </graph>
		</graphml>
	'''

	def private print(Connection connection) '''
		<edge source="«(connection.source as Instance).name»" sourceport="«connection.sourcePort.name»" target="«(connection.target as Instance).name»" targetport="«connection.targetPort.name»">
		    <data key="edge_prod">«((connection.source as Instance).getActor.moC as CSDFMoC).outputPattern.numTokensMap.get(connection.sourcePort)»</data>
		    <data key="edge_delay">«connection.printDelays»</data>
		    <data key="edge_cons">«((connection.target as Instance).getActor.moC as CSDFMoC).inputPattern.numTokensMap.get(connection.targetPort)»</data>
		    <data key="data_type">«connection.sourcePort.type.doSwitch»</data>
		</edge>
	'''

	def private printDelays(Connection connection) {
		if (((connection.source as Instance).getActor.moC as CSDFMoC).delayPattern.numTokensMap.containsKey(connection.sourcePort)) {
			((connection.source as Instance).getActor.moC as CSDFMoC).delayPattern.numTokensMap.get(connection.sourcePort)
		} else {
			"0"
		}
	}

	def private print(Instance instance) '''
		<node id="«instance.name»" kind="vertex">
		<data key="graph_desc">../Code/IDL/«instance.getActor.simpleName».idl</data>
		<data key="name">«instance.getActor.simpleName»</data>
			«IF instance.arguments.empty»
				<data key="arguments"/>
			«ELSE»
				«FOR arg : instance.arguments»
					«arg.print»
				«ENDFOR»
			«ENDIF»
		</node>
		«IF !instance.getActor.stateVars.empty»
			<edge source="«instance.name»" sourceport="stateVars_o" target="«instance.name»" targetport="stateVars_i">
				<data key="edge_prod">1</data>
				<data key="edge_delay">1</data>
				<data key="edge_cons">1</data>
			    <data key="data_type">struct StateVars *</data>
			</edge>
		«ENDIF»
	'''

	def private print(Argument argument) '''
		<data key="arguments">
			<argument name="«argument.variable.name»" value="«argument.value.doSwitch»"/>
		</data>
	'''
}