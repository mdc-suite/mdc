package it.unica.diee.mdc.merging;

import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Port;
import net.sf.orcc.graph.Vertex;

/**
 * TODO \todo to check
 * 
 * This class provides methods to assign the label to a vertex or port.
 * It calls Class it.unica.diee.mdc.merging.Label()
 * 
 * @author Carlo Sau
 *
 */
public class Labeler {
	
	
	public Label getLabel(Vertex vertex, Port port){
		if(vertex.getAdapter(Port.class) != null) {
			return new Label(vertex.getAdapter(Port.class),null);
		} else {
			return new Label(port,vertex.getAdapter(Instance.class));
		}
	}
	
	public Label getLabel(Vertex vertex){
		if(vertex.getAdapter(Port.class) != null) {
			return new Label(vertex.getAdapter(Port.class),null);
		} else {
			return new Label(null,vertex.getAdapter(Instance.class));
		}
	}

}
