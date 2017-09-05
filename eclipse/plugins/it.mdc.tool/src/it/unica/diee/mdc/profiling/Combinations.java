package it.unica.diee.mdc.profiling;

import java.util.*;

import net.sf.orcc.df.Network;


public class Combinations{

	private List<Network> inputNetworks;
	private Map<Integer, List<List<Network>>> combinationsMap;
	private Map<Integer, List<List<Network>>> combinationsMap_NR;
	
	public Combinations(List<Network> input) {
		inputNetworks = new ArrayList<Network>(input);
		combinationsMap = new HashMap<Integer,List<List<Network>>>(); // initialize the original input Map
		combinationsMap_NR = new HashMap<Integer,List<List<Network>>>(); // non redundant combinations map
		
		//System.out.println("size: "+ inputNetworks.size());
	}
	
	public Map<Integer, List<List<Network>>> getMap(){
		return combinationsMap;
	}
	
	public Map<Integer, List<List<Network>>> getMap_NR(){
		return combinationsMap_NR;
	}
	
	
	public void createComb(){
		Integer key=1;
		for (int i=0; i<inputNetworks.size(); i++){
			List<Network> list = new ArrayList<Network>(inputNetworks);
			Network elementP1 = list.get(i); //elementP1 is the index a network to be placed in parallel
			List<Network> v1=new ArrayList<Network>();
            v1.add(elementP1);
            Collection<Network> listToPermute=new ArrayList<Network>();
            listToPermute.addAll(inputNetworks);
            listToPermute.remove(elementP1);
            Permutations<Network> obj = new Permutations<Network>();
            Collection<List<Network>> output = obj.permute(listToPermute);
            Iterator<List<Network>> itr = output.iterator();
            
            while(itr.hasNext()) {
            	List<Network> elm = itr.next();
                //System.out.println(elm + " ");
                List<List<Network>> value=new ArrayList<List<Network>>();
                //System.out.println("*********OUTERN********");
                value.add(v1);
                value.add(elm);
                //System.out.println("v1: "+ v1+ " elm: "+ elm + " value" + value);
                
                combinationsMap.put(key, value);
                key=key+1;
                /*System.out.println((key-1));
                System.out.println(value);
                System.out.println(" "+ combinationsMap);*/
                //System.out.println("*********************");
                List<Network> comb=new ArrayList<Network>();
                comb.addAll(elm);
                
                /*System.out.print("key: " + (key-1)); 
                System.out.print(" subset: " + SubSets); 
                System.out.println(" size " + SubSets.size());*/
                
                List<Network> tempV=new ArrayList<Network>();
                while(comb.size() >2 ){
                	//System.out.println("size1 " + SubSets.size());
                	Network  elementP2= comb.get(0); //elementP2 is the index an additional network (till N-2) to be placed in parallel
                	comb.remove(elementP2);
                	/*System.out.println("*********INNER********");
                	System.out.print(key);
                	System.out.print(" subset: " + comb); 
                    System.out.println(" size " + comb.size());*/
                   
                	//System.out.println("original v1 " + v1);
                	
                    
                	//all permutations have already been calculated 
                	//e.g. for element [1] --> [2,3,4] [3,2,4],[3,4,2],[2,4,3],[4,2,3],[4,3,2]
                	//I need to extract [2], [3] and [4] and add them to the list of network to be placed in parallel along with [1]
                	//and the combinations of merged nework will be [1,2] --> [3,4] and [4,3] and so on
                	List<Network> v2=new ArrayList<Network>();
                    v2.addAll(v1);
                    v2.addAll(tempV);
                    v2.add(elementP2); //add the new element to the previous V1 list
                    
                	//System.out.println("v1 " + v1);
                    List<Network> tempComb=new ArrayList<Network>();
                    tempComb.addAll(comb);
                    List<List<Network>> value2=new ArrayList<List<Network>>();
                    value2.add(v2);
                    value2.add(tempComb);
                	//System.out.println("value2 "+ value2);
                    //System.out.println(" subset: " + comb); 
                    
                    combinationsMap.put(key, value2);
                    key=key+1;
                    //System.out.println(" "+ combinationsMap);
                    //System.out.println("*********************");
                    tempV.add(elementP2);
                }
                
            } 
		}
		//System.out.println(combinationsMap);
	}
	
	// find all the index with the same merging list in the map
	public List<List<Integer>> sameCombFinder(Map<Integer, List<List<Network>>> inputMap) {
		
		List<List<Integer>> result = new ArrayList<List<Integer>>();
		boolean isAlreadySigned = false;
		
		for(Integer key : inputMap.keySet()){

			isAlreadySigned = false;
			
			for(List<Integer> resList : result)
				if(resList.contains(key))
					isAlreadySigned = true;
			
			if(!isAlreadySigned) {
				List<List<Network>> value = inputMap.get(key);
				List<Network> ref = value.get(1);
				List<Integer> sameCombList = findSameMerged(inputMap,ref);
				if(sameCombList != null)
					result.add(sameCombList);
			}
			
		}	
		
		return result;
	}
	
	// find all the index with the ref merging list in the map
		public List<Integer> findSameMerged(Map<Integer, List<List<Network>>> inputMap, List<Network> ref){
			
			Map<Integer, List<List<Network>>> localMap = new HashMap<Integer,List<List<Network>>>(inputMap);
			List<Integer> keys=new ArrayList<Integer>();
			
			// iterator on the values (lists of lists (two) of integers)
			// iterator on the keys (integers)
			Iterator<Integer>  itrK = localMap.keySet().iterator();				
			
			// analyze all the values
			while(itrK.hasNext()) {
				
				Integer elemK =  itrK.next();
				List<List<Network>> elemV =  localMap.get(elemK);	// two current list of integers
								// respective current key (integer)
				
				// verify if merge list of integers of the current element contains ref
	         	if(elemV.get(1).equals(ref)){
	        		
	         		//System.out.println("chiave: " + elemK + " elemento: " + elemV + " test : " + elemV + " ref "+ ref);		
	         		keys.add(elemK);

	         	}
	         }
			
			if(keys.size()==1)
				return null;
			else
				return keys;
			
		}
		
		
			// find all the keys of the items to be removed from the map
			public List<Integer> findEquals(Map<Integer, List<List<Integer>>> inputMap, List<Integer> keyEquals){
				
				List<Integer> keys=new ArrayList<Integer>();
				Map<Integer, List<List<Integer>>> localMap = new HashMap<Integer,List<List<Integer>>>();
				// iterator on the given keys (integers)
				Iterator<Integer>  itrK = keyEquals.iterator();	
				// analyze all the given input keys to create the subset of the input map with the possibly identical configuration 
				while(itrK.hasNext()) {
					Integer tempK=itrK.next();
					//System.out.println("chiave: " + tempK + " elemento: " + inputMap.get(tempK));		
					localMap.put(tempK, inputMap.get(tempK));
				}
				
				
				Collection<List<List<Integer>>> mapValues = new ArrayList<List<List<Integer>>>(localMap.values());  // all the values (lists of lists (two) of int)
				Collection<Integer> mapKeys = new HashSet<Integer>(localMap.keySet());  							// all the keys (int)
				
				// iterator on the values (lists of lists (two) of integers)
				Iterator<List<List<Integer>>> itrV = mapValues.iterator();
				// iterator on the keys (integers)
				Iterator<Integer>  itrK2 = mapKeys.iterator();	
				
				int size=mapKeys.size();
				// analyze all the values 
				while(itrV.hasNext()) {
					
					List<List<Integer>> l1 = new ArrayList<List<Integer>>();
					List<List<Integer>> elemV1 = itrV.next();	// two current list of integers				
					l1.addAll((List<List<Integer>>) elemV1);
					
					List<List<Integer>> l2 = new ArrayList<List<Integer>>();
					Integer elemK=0;
					if(itrV.hasNext()) {
						List<List<Integer>> elemV2 =  itrV.next();	// two current list of integers
						elemK =  itrK2.next();				// key to be eventually removed
						l2.addAll((List<List<Integer>>) elemV2);
					}

					// verify if merge list of integers of the current element contains ref
					if(!l2.isEmpty())
						if(l1.get(0).containsAll(l2.get(0)))		
							keys.add(elemK);
		         	size=size-1;
					
		         }
				
				if(keys.size()==0)
					return null;
				else
					return keys;
				
			}
			
			
			public Map<Integer, List<List<Network>>> removeRedundancy(Map<Integer, List<List<Network>>> inputMap, List<Integer> keyRed){
				
				Map<Integer, List<List<Network>>> localMap = new HashMap<Integer,List<List<Network>>>(inputMap);
				// iterator on the given keys (integers)
				Iterator<Integer>  itrK = keyRed.iterator();
				
				// analyze all the given input keys to create the subset of the input map with the possibly identical configuration 
				while(itrK.hasNext()) {
					Integer tempK=itrK.next();
					localMap.remove(tempK);
				}
				
				return localMap;
				
			}

					
					public void removeALL(){
						
						//System.out.println("************* REMOVAL ******************");	
						
						Map<Integer, List<List<Network>>> localMap = new HashMap<Integer,List<List<Network>>>();
						localMap.putAll(combinationsMap); //insert all the input combinations within a local copy of the map
						
						Collection<List<List<Network>>> mapValues = new ArrayList<List<List<Network>>>(localMap.values());  // all the values (lists of lists (two) of int)						
						    
						// iterator on the values (lists of lists (two) of integers)
						Iterator<List<List<Network>>> itrV = mapValues.iterator();
						// iterator on the keys (integers)
						//Iterator<Integer>  itrK = mapKeys.iterator();	
						
						while(itrV.hasNext()) {
							
							List<Integer> keys=new ArrayList<Integer>(); //set of keys of the elements with the same merged set
							//List<Integer> keys2=new ArrayList<Integer>(); //set of keys of the elements with the same merged set
						   
							//extract all the values of merged networks to use them as reference
							List<List<Network>> elemV =  itrV.next();	// two current list of integers
							//Integer elemK =  itrK.next();				// respective current key (integer)
							//System.out.println("chiave: " + elemK + " elemento: " + elemV);	
							
							// extraction of the reference 
							List<Network> ref = new ArrayList<Network>();
							ref.addAll(((List<List<Network>>) elemV).get(1));
							//System.out.println("ref: " + ref);	
							
							keys=this.findSameMerged(localMap,ref);
							
							//System.out.println("list of Keys with overlapping merged networks: " + keys);
							
							if (keys==null||keys.isEmpty()){
								//System.out.println("No redundancy on reference: " + ref);
							}
							else{
								keys.remove(0);
								//keys2=this.findEquals(localMap,keys);
								/*System.out.println("list of Keys with redundant element: " + keys2);
								System.out.println("BEFORE localMap:");
								System.out.println(localMap);*/
								//if(keys2!=null)
									localMap=this.removeRedundancy(localMap,keys);
								/*System.out.println("AFTER localMap:");
								System.out.println(localMap);*/
							}
							
							
						}
						
						//finally writes the list of non redundant networks
						combinationsMap_NR.putAll(localMap);
						return;

					}
		 
	
	
}
