package it.mdc.tool.core.multiDataflowGenerator;

import java.util.Set;

import net.sf.orcc.df.Argument;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;

import org.eclipse.emf.ecore.util.EcoreUtil;

/**
 * Verify if two basic network elements are sharable
 * 
 * @author Carlo Sau
 *
 */
public class Unifier {
		
	/**
	 * Verify if the existing actor instance is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate actor instance
	 * @param existing
	 * 				the existing actor instance
	 * @return
	 * 		if the existing actor instance is sharable with the candidate one
	 */
	public boolean canUnify(Instance i1, Instance i2) {
		if (i1.getActor() == i2.getActor()) {
			for (Argument arg1 : i1.getArguments()) {
				for (Argument arg2 : i2.getArguments()) {
					if (arg1.getVariable() == arg2.getVariable()) {
						if (!EcoreUtil.equals(arg1.getValue(), arg2.getValue())) {
							return false;
						}
					}
				}
			}
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Verify if the existing port is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate port
	 * @param existing
	 * 				the existing port
	 * @return
	 * 		if the existing port is sharable with the candidate one
	 */
	public boolean canUnify(Port candidate, Port existing) {
		if(candidate == null && existing == null)
			return true;
		if((candidate == null && existing != null)||(candidate != null && existing == null))
			return false;
		if(candidate.getName().equals(existing.getName()) && EcoreUtil.equals(
				candidate.getType(), existing.getType())){
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Verify if the existing vertex is sharable with the candidate one.
	 * (useful for future works on networks internal reconfiguration)
	 * 
	 * @param candidate
	 * 				the candidate vertex
	 * @param existing
	 * 				the existing vertex
	 * @return
	 * 		if the existing vertex is sharable with the candidate one
	 */
	public boolean canUnify(Vertex candidate, Vertex existing) {
		if(candidate == null && existing == null)
			return true;
		else if(candidate == null || existing == null)
			return false;
		if ((candidate.getAdapter(Instance.class) != null) && (existing.getAdapter(Instance.class) != null)) {
			return canUnify(candidate.getAdapter(Instance.class), existing.getAdapter(Instance.class));
		} else if ((candidate.getAdapter(Port.class) != null) && (existing.getAdapter(Port.class) != null)) {
			return canUnify(candidate.getAdapter(Port.class), existing.getAdapter(Port.class));
		} else {
			return false;
		}
	}

	/**
	 * Verify if the existing actor instance is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate actor instance
	 * @param existing
	 * 				the existing actor instance
	 * @return
	 * 		if the existing actor instance is sharable with the candidate one
	 */
	public boolean canUnifyMultiple(Instance candidate, Instance existing) {
		
		if(candidate.hasAttribute("count") && existing.hasAttribute("count"))
			if (candidate.getAttribute("count").getObjectValue() != existing.getAttribute("count").getObjectValue())
				return false;
		
		return canUnify(candidate,existing);
	}

	/**
	 * Verify if the existing vertex is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate vertex
	 * @param existing
	 * 				the existing vertex
	 * @return
	 * 		if the existing vertex is sharable with the candidate one
	 */
	public boolean canUnifyMultiple(Vertex candidate, Vertex existing) {
		if(candidate == null && existing == null)
			return true;
		else if(candidate == null || existing == null)
			return false;
		if ((candidate.getAdapter(Instance.class) != null) && (existing.getAdapter(Instance.class) != null)) {
			return canUnifyMultiple(candidate.getAdapter(Instance.class),existing.getAdapter(Instance.class));
		} else if ((candidate.getAdapter(Port.class) != null) && (existing.getAdapter(Port.class) != null)) {
			return canUnify(candidate.getAdapter(Port.class), existing.getAdapter(Port.class));
		} else {
			return false;
		}
	}
	
	/**
	 * Verify if the existing actor instances set is sharable with the candidate one.
	 * 
	 * @param candidate
	 * 				the candidate actor instances set
	 * @param existing
	 * 				the existing actor instances set
	 * @return
	 * 		if the existing actor instances set is sharable with the candidate one
	 */
	public boolean canUnifySets(Set<Instance> candidate, Set<Instance> existing) {
		
		if(candidate.size()!=existing.size())
			return false;
		
		int count = 0;
		
		for(Instance inst1 : candidate) {
			cycle : for(Instance inst2 : existing) 
				if(canUnifyMultiple(inst1,inst2)) {
					count++;
					break cycle;
				}
		}
		
		if(count == candidate.size())
			return true;
		else
			return false;
	}
	
}