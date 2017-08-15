package it.unica.diee.mdc;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

/**
 * <!-- begin-user-doc --> 
 * This class defines an acquisition by the standard input. 
 * end-user-doc -->
 *
 *
 * <p>
 * </p>
 *
 * @see
 */
public class Acquire {
	
	/**
	 * This method acquires the number of networks to be merge by the standard input
	 * and return this number as a float number.
	 * 
	 * @return
	 */
	protected float readNumberNetworks(){
		float f = 3;
		String s;
		BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
		System.out.println("\n Insert networks number for merge:  ");
		try {
	      s = br.readLine();
	      f = Float.parseFloat(s);   
	   } catch (IOException e1) {
	      System.out.println ("\n Error flow");
	   } catch (Exception e1){
		   System.out.println ("\n Invalid value inserted!\n Raised Exception: " + e1);
		   return readNumberNetworks();
	   }
  
		return f;
	}
	
	/**
	 * This method read the name of a network by the standard input and return 
	 * this name as a String object.
	 * 
	 * @return
	 */
	protected String readName(){
		String name;
		System.out.println("\n Insert network name:  ");
		try {
			BufferedReader input = new BufferedReader(new InputStreamReader(System.in));
			name = input.readLine(); 
			return name;	
		} catch (IOException e1) {
			   // Print out the exception that occurred
			   System.out.println("\n Unable to create");
		} 

		return "Not acquired";	
	}
	
	/**
	 * This method read the choice (y/n) by the standard input and return this choice
	 * as a boolean object.
	 * 
	 * @return
	 */
	protected boolean readChoice(){
		String choice;
		System.out.println("\n Do you want to preserve multiple instances for the same actor? (y/n)  ");
		try {
			BufferedReader input = new BufferedReader(new InputStreamReader(System.in));
			choice = input.readLine();
			if(choice.equals("y")) {
				return true;
			} else if (choice.equals("n")){
				return false;
			} else {
				System.out.println("\n Invalid choiche! Please insert a valid value!");
				this.readChoice();
			}

			
		} catch (IOException e1) {
		    System.out.println("\n Unable to create");
		} catch (Exception e1) {
			System.out.println("\n The inserted choice is not valid!");
			return this.readChoice();
		}
		return false;
		
	}

		protected boolean readChoiceCg(){
			String choice;
			System.out.println("\n Do you want to enable clock gating? (y/n)  ");
			try {
				BufferedReader input = new BufferedReader(new InputStreamReader(System.in));
				choice = input.readLine();
				if(choice.equals("y")) {
					return true;
				} else if (choice.equals("n")){
					return false;
				} else {
					System.out.println("\n Invalid choiche! Please insert a valid value!");
					this.readChoiceCg();
				}

				
			} catch (IOException e1) {
			    System.out.println("\n Unable to create");
			} catch (Exception e1) {
				System.out.println("\n The inserted choice is not valid!");
				return this.readChoice();
			}
		
		return false;
		
	}
	
	/**
	 * This method read the choice (y/n) by the standard input and return this choice
	 * as a boolean object.
	 * 
	 * @return
	 */
	protected boolean readBroadcastChoice(){
		String choice;
		System.out.println("\n Do you want to merge different broadcasts with the same source port? (y/n)  ");
		try {
			BufferedReader input = new BufferedReader(new InputStreamReader(System.in));
			choice = input.readLine();
			if(choice.equals("y")) {
				return true;
			} else if (choice.equals("n")){
				return false;
			}

			
		} catch (IOException e1) {
		    System.out.println("\n Unable to create");
		} catch (Exception e1) {
			System.out.println("\n The inserted choice is not valid!");
			return this.readBroadcastChoice();
		}

		return false;
		
	}

}
