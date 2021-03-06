package it.mdc.tool.core.multiDataflowGenerator;

import net.sf.orcc.df.Argument;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Port;
import net.sf.orcc.ir.Expression;
import net.sf.orcc.ir.util.ExpressionEvaluator;
import net.sf.orcc.util.OrccLogger;

/**
 * This class provides methods to manage object labels.
 * 
 * @author Carlo Sau
 *
 */
public class Label{

	private Port port;
	
	private Instance instance;
	
	private ExpressionEvaluator evaluator;
	
	/**
	 * @param port
	 * @param instance
	 */
	public Label(Port port, Instance instance) {
		this.port = port;
		this.instance = instance;
		this.evaluator = new ExpressionEvaluator();
	}
	
	/**
	 *  
	 * @return port
	 */
	public Port getPort() {
		return port;
	}
	
	/**
	 * 
	 * @return instance
	 */
	public Instance getInstance() {
		return instance;
	}
	
	@Override
	/**
	 * This method compare the given object with another one. 
	 * 				
	 * @return boolean
	 */
	public boolean equals(Object labelObject) {
		if(!(labelObject instanceof Label)) {	// object to be compared is not a label
			return false;
		}
		Label label = (Label) labelObject;
		if((label.getInstance() != null) && (this.getInstance() != null)) { // both labels refer instances
			Instance instance = label.getInstance();
			if (!this.instance.getActor().equals(instance.getActor())) { // labels reference different actors
				return false;
			} else { //labels reference the same actor
				if(!(label.getPort() == null || this.port == null)) {	// labels reference non-null ports
					if(!label.getPort().getName().equals(this.port.getName())) { // labels ports are different
						return false;
					} else if(!label.getPort().getType().equals(this.port.getType())) {
						return false;
					}
				} else {
					// TODO this condition could be wrong (&& instead of !! in internal conditions, but it determines problems in clique finder
					if( (label.getPort() == null || this.port != null) ||
							(label.getPort() != null || this.port == null) ) {
						return false;
					}
				}
				for(Argument a : instance.getArguments()) { // iterate on comparing instance arguments
					if(evaluator.evaluateAsInteger((Expression) a.getValue()) != 
							evaluator.evaluateAsInteger((Expression) this.instance.getArgument(a.getVariable().getName()).getValue())) { // one of the labels instances arguments has not the same value
						return false;
					}
				}
			}
		}
		if((label.getInstance() == null) && (this.getInstance() == null)) {
			// TODO control on port name (needed for a fair comparison with EmpiricMerger)
			if(!label.getPort().getName().equals(this.port.getName())) {
				return false;	
			}
			if(!label.getPort().getType().equals(this.port.getType())) {
				return false;
			}
		}
		if( ((label.getInstance() != null) && (this.getInstance() == null)) ||
				((label.getInstance() == null) && (this.getInstance() != null)) ) {
			return false;
		}
		return true;
		
	}
	
}

