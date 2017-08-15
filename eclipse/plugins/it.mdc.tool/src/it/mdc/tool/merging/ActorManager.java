package it.mdc.tool.merging;

import java.util.Map;
import java.util.HashMap;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.Instance;
import net.sf.orcc.df.Network;
import net.sf.orcc.graph.Vertex;

/**
 * Manage actor names and count in the multi-dataflow network.
 * 
 * @author Carlo
 *
 */
public class ActorManager {

	/**
	 * Map each actor with a progressive count to rename the 
	 * related instances
	 */
	private Map<Actor,Integer> actorCount;

	
	/**
	 * The constructor
	 */
	public ActorManager() {
		actorCount = new HashMap<Actor,Integer>();
	}
	
	/**
	 * Rename the instance with its actor name plus the progressive
	 * count. Verify if already there is an instance with the same name in 
	 * the given network.
	 * 
	 * @param instance
	 * 		the instance to be renamed
	 * @param netwok
	 * 		the given network
	 */
	public void renameInstance(Instance instance, Network network) {
		Actor actor = instance.getAdapter(Actor.class);
		String name = actor.getSimpleName();
		String name_extension = "";
		
		if(!isPresentActor(actor))
			actorCount.put(actor, 0);
		for(Vertex vertex : network.getChildren())
			if(vertex.getAdapter(Instance.class) != null)
				if(vertex.getAdapter(Instance.class).getName().equals(name + "_" + actorCount.get(actor))) {
					//TODO solve problem (is it a real problem??) different cal actors with the same name
					name_extension = "2";
				}
					
		instance.setName(name + name_extension + "_" + actorCount.get(actor));
		instance.setAttribute("count", (Integer) actorCount.get(actor));
	}
	
	/**
	 * Verify if the progressive count of the given actor is already 
	 * present in the map.
	 * 
	 * @param actor
	 * 		the given actor
	 * @return
	 * 		if the progressive count of the given actor is already 
	 * 		present in the map
	 */
	public boolean isPresentActor(Actor actor) {
		return actorCount.containsKey(actor);
	}
	
	/**
	 * Increment the progressive count of the given actor. 
	 * If the counter is not initialized, it is set to 0.
	 * 
	 * @param actor
	 * 		the given actor
	 */
	public void incrActorCount(Actor actor) {
		if(actor == null)
			return;
		if(!isPresentActor(actor)) {
			actorCount.put(actor, 0);
		} else {
			actorCount.put(actor, actorCount.get(actor) +1);
		}
	}
	
}
