package it.mdc.tool.sboxManagement; 

import java.io.File;
import java.io.IOException;

import net.sf.orcc.df.Actor;
import net.sf.orcc.df.DfFactory;
import net.sf.orcc.ir.IrFactory;
import net.sf.orcc.ir.Type;
import net.sf.orcc.ir.util.IrUtil;

/**
 * Manage the Switching Box (SBox) actor
 * 
 * @author Carlo Sau
 *
 */
public class SboxActorManager {
	
	/**
	 * The generic SBox 1-input 2-outputs actor
	 */
	private Actor sboxActor1x2;
	
	/**
	 * The generic SBox 2-inputs 1-output actor
	 */
	private Actor sboxActor2x1;
	
	/**
	 * Progressive count of SBox actors.
	 */
	private int sboxCounter;
	
	/**
	 * The constructor
	 */
	public SboxActorManager () {
		
		sboxActor1x2 = DfFactory.eINSTANCE.createActor();
		sboxActor2x1 = DfFactory.eINSTANCE.createActor();
		sboxCounter = 0;
		initializeSboxActors();
	}
	
	/**
	 * Initialize the sbox actors with ports and attributes
	 */
	public void initializeSboxActors() {		
		sboxActor1x2.setAttribute("sbox", (Object) null);
		sboxActor1x2.setAttribute("type", "1x2");
		sboxActor2x1.setAttribute("sbox", (Object) null);
		sboxActor2x1.setAttribute("type", "2x1");
		sboxActor1x2.getParameters().add(
				IrFactory.eINSTANCE.createVarInt("SIZE", true, 0));
		sboxActor2x1.getParameters().add(
				IrFactory.eINSTANCE.createVarInt("SIZE", true, 0));
		sboxActor1x2.setNative(true);
		sboxActor2x1.setNative(true);
		//sboxActor1x2.setName("sbox1x2");
		//sboxActor2x1.setName("sbox2x1");
	}
	
	/**
	 * Set SBox actors CAL files for graphic editor view
	 * 
	 * @param sbox1x2
	 * @param sbox2x1
	 * @throws IOException
	 */
	public void initializeSboxCalFiles(String path) throws IOException {
		if(path.contains("src.")){
			sboxActor1x2.setFileName(path + File.separator + "Sbox1x2.cal");
			String calPathSbox1x2 = path.replace("\\", ".").split("src.")[1] + ".Sbox1x2";
			sboxActor1x2.setName(calPathSbox1x2);
			
			sboxActor2x1.setFileName(path + File.separator + "Sbox2x1.cal");
			String calPathSbox2x1 = path.replace("\\", ".").split("src.")[1] + ".Sbox2x1";
			sboxActor2x1.setName(calPathSbox2x1);
		}
	}
	
	/**
	 * Return the SBox progressive counter value
	 * 
	 * @return
	 * 		the SBox progressive counter value
	 */
	public Integer getSboxCount() {
		return sboxCounter;
	}
	
	/**
	 * Increment the SBox progressive counter value
	 */
	public void incrementSboxCount() {
		sboxCounter = (sboxCounter + 1); 
	}
	
	/**
	 * Return the proper 1-input 2-outputs SBox actor 
	 * basing on the given desired type.
	 * 
	 * @param type
	 * 		the given desired type
	 * @return
	 * 		the proper SBox actor
	 */
	public Actor getSboxActor1x2(Type type) {
		
		Actor sboxActor;
		//int endIndex;
		
		if(type.isBool()) {
			
			sboxActor = IrUtil.copy(sboxActor1x2);
			/*endIndex = sboxActor1x2.getFileName().lastIndexOf(".");
			sboxActor.setFileName(sboxActor1x2.getFileName().substring(0, endIndex) + "bool.cal");
			String calPath = sboxActor.getFileName().replace("\\", ".").split("src.")[1];
			endIndex = calPath.lastIndexOf(".");
			calPath = calPath.substring(0, endIndex);*/
			sboxActor.setName("Sbox1x2bool");
			
		} else if (type.isFloat()) {
						
			sboxActor = IrUtil.copy(sboxActor1x2);
			//if(sboxActor1x2.getFileName() != null){
				/*endIndex = sboxActor1x2.getFileName().lastIndexOf(".");
				sboxActor.setFileName(sboxActor1x2.getFileName().substring(0, endIndex) + "float.cal");
				String calPath = sboxActor.getFileName().replace("\\", ".").split("src.")[1];
				endIndex = calPath.lastIndexOf(".");
				calPath = calPath.substring(0, endIndex);*/
				sboxActor.setName("Sbox1x2float");
			//}
			
		} else if (type.isInt() || type.isUint()) {
			
			sboxActor = IrUtil.copy(sboxActor1x2);
			/*if(sboxActor1x2.getFileName() != null){
				endIndex = sboxActor1x2.getFileName().lastIndexOf(".");
				sboxActor.setFileName(sboxActor1x2.getFileName().substring(0, endIndex) + "int" + type.getSizeInBits() + ".cal");
				String calPath = sboxActor.getFileName().replace("\\", ".").split("src.")[1];
				endIndex = calPath.lastIndexOf(".");
				calPath = calPath.substring(0, endIndex);*/
				sboxActor.setName("Sbox1x2int" + type.getSizeInBits());	
			//}
			
		} else {
			
			sboxActor = IrUtil.copy(sboxActor1x2);
			sboxActor.setName("Sbox1x2");
			
		}
		return sboxActor;
		
	}
	
	/**
	 * Return the proper 2-inputs 1-output SBox actor 
	 * basing on the given desired type.
	 * 
	 * @param type
	 * 		the given desired type
	 * @return
	 * 		the proper SBox actor
	 */
	public Actor getSboxActor2x1(Type type) {
		
		Actor sboxActor;
		//int endIndex;
		
		if(type.isBool()) {
			
			sboxActor = IrUtil.copy(sboxActor2x1);
			/*endIndex = sboxActor2x1.getFileName().lastIndexOf(".");
			sboxActor.setFileName(sboxActor2x1.getFileName().substring(0, endIndex) + "bool.cal");
			String calPath = sboxActor.getFileName().replace("\\", ".").split("src.")[1];
			endIndex = calPath.lastIndexOf(".");
			calPath = calPath.substring(0, endIndex);*/
			sboxActor.setName("Sbox2x1bool");
			
		} else if (type.isFloat()) {
			
			sboxActor = IrUtil.copy(sboxActor2x1);
			/*if(sboxActor2x1.getFileName() != null){
				endIndex = sboxActor2x1.getFileName().lastIndexOf(".");
				sboxActor.setFileName(sboxActor2x1.getFileName().substring(0, endIndex) + "float.cal");
				String calPath = sboxActor.getFileName().replace("\\", ".").split("src.")[1];
				endIndex = calPath.lastIndexOf(".");
				calPath = calPath.substring(0, endIndex);*/
				sboxActor.setName("Sbox2x1float");
			//}
			
		} else if (type.isInt() || type.isUint()) {
			
			sboxActor = IrUtil.copy(sboxActor2x1);
			/*if(sboxActor2x1.getFileName() != null){
				endIndex = sboxActor2x1.getFileName().lastIndexOf(".");
				sboxActor.setFileName(sboxActor2x1.getFileName().substring(0, endIndex) + "int" + type.getSizeInBits() + ".cal");
				String calPath = sboxActor.getFileName().replace("\\", ".").split("src.")[1];
				endIndex = calPath.lastIndexOf(".");
				calPath = calPath.substring(0, endIndex);*/
				sboxActor.setName("Sbox2x1int" + type.getSizeInBits());
			//}
			
		} else {
			
			sboxActor = IrUtil.copy(sboxActor2x1);
			sboxActor.setName("Sbox2x1");
			
		}
		
		return sboxActor;
		
	}
	
}