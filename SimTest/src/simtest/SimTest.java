/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package simtest;

import java.util.LinkedList;
import java.util.Random;

/**
 *
 * @author rlaka
 */
public class SimTest {
    public static Random rand = new Random();
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        Screen screen = new Screen();
        long DELAY_MS = 20;
        
        LinkedList<Ball> balls = new LinkedList<>();
        for (int i = 0; i < 5; i++){
            balls.add(new Ball());
        }


        
        long timeMs = System.nanoTime() / 1000000;
        
        while(true){            
            for (Ball ball : balls){
                ball.move(0.25);
            }
            
            screen.sg.eraseAllDrawables();
            for (Ball ball : balls){
                ball.draw(screen);
            }
            screen.sg.repaintPanel();
            try {
                long now = System.nanoTime() / 1000000;
                long sleepyTime = timeMs + DELAY_MS - now;
                timeMs = now;
                if (sleepyTime > 0){
                    Thread.sleep(20);
                }                
            } catch (InterruptedException ex) {                
            }
        }                
    }    
}
