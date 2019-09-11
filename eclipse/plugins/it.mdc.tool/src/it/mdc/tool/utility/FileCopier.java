package it.mdc.tool.utility;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class FileCopier {
	
	
	public void delete(File file) {
		File[] delFiles = file.listFiles();
		if(file.isDirectory()) {
			for(File delFile : delFiles) {
				delete(delFile);
			}
			file.delete();
		} else {
			file.delete();
		}
	}
	
	public void copy(String sourceLocation, String targetLocation) throws IOException {
	    File sourceFile = new File(sourceLocation);
	    File targetFile = new File(targetLocation);
	    if(!targetFile.exists()) {
	    	targetFile.mkdir();
	    }
	    copy(sourceFile,targetFile);
	}
	
	public void copyOnlyFiles(String sourceLocation, String targetLocation) throws IOException {
	    File sourceFile = new File(sourceLocation);
	    File[] subFolders = sourceFile.listFiles();
	    
	    for (File subFolder : subFolders) {	    	
            if (!subFolder.getName().replace(sourceLocation, "").equals("lib") && !subFolder.getName().replace(sourceLocation, "").equals("tb")){
            	File destination = new File(targetLocation + File.separator + subFolder.getName().replace(sourceLocation, ""));
            	copy(subFolder,destination);
            } 
	    }
	}
	
	
	
	public void copy(File sourceLocation, File targetLocation) throws IOException {
	    if (sourceLocation.isDirectory()) {
	        copyDirectory(sourceLocation, targetLocation);
	    } else {
	        copyFile(sourceLocation, targetLocation);
	    }
	}

	private void copyDirectory(File source, File target) throws IOException {
	    if (!target.exists()) {
	        target.mkdir();
	    }

	    for (String f : source.list()) {
	        copy(new File(source, f), new File(target, f));
	    }
	}

	private void copyFile(File source, File target) throws IOException {        
	    try (
	    		
	            InputStream in = new FileInputStream(source);
	            OutputStream out = new FileOutputStream(target)
	    ) {
	    	
	        byte[] buf = new byte[1024];
	        int length;
	        while ((length = in.read(buf)) > 0) {
	            out.write(buf, 0, length);
	        }
	    }
	}
}
