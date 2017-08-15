package it.mdc.tool.utility;


import java.io.File;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.IOException;

/**
 * This class extract the path of an actor in the workspace
 * by its Cal file.
 * 
 * @author Carlo Sau
 *
 */
public class PathDefiner {

	/**
	 * The buffered reader
	 */
	private BufferedReader reader;
	
	/**
	 * The constructor
	 * 
	 * @param path
	 * @throws IOException
	 */
	public PathDefiner(String path) throws IOException {

		reader = new BufferedReader(new FileReader(new File(path)));
		
	}
	
	/**
	 * Get the actor path by the Cal file that is reading the reader 
	 * 
	 * @return
	 * @throws IOException
	 */
	public String getPath() throws IOException {
	
		String nextLine;
		String path = null;
		String actorName = null;
		
		while( (nextLine = reader.readLine()) != null ) {
			
			// package line
			if (nextLine.contains("package")){
				path=nextLine.split(";")[0].split(" ")[1];
			}
			
			// actor declaration line
			if (nextLine.contains("actor")){
				actorName=nextLine.split("\\(")[0].split(" ")[1];
			}
			
			// return the complete path
			if (path != null && actorName != null){
				return path + "." + actorName;
			}
		}

		return null;			
	}		

}
