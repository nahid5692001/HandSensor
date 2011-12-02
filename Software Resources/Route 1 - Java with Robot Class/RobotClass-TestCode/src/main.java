
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.event.KeyEvent;


public class main {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		
		try {

				Robot robot = new Robot();
				for ( int i = 10; i < 1000; i++)
				{
					robot.mouseMove(i, 100);
					robot.delay(2);
				}
				
			} catch (AWTException e) {
				e.printStackTrace();
			} 
		
		
	}

}
