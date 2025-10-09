/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package simtest;

/**
 *
 * @author rlaka
 */
public class Ball {
    private static final int CNT_ACC_UPDATE = 20;
    private static final double MAX_SPEED = 6.0;
    private static final int NUM_TAILSEGMENTS = 20;
   
    TupleD pos;
    TupleD speed;
    TupleD acc;
    int accCounter;
    Accelerator accelerator;
    TupleD[] tail = new TupleD[NUM_TAILSEGMENTS];
    
    
    
    
    // -------------------------------------------------------------------------
    public Ball(){
        pos = new TupleD(Screen.WIDTH/2, Screen.HEIGHT/2);
        for (int i = 0; i < NUM_TAILSEGMENTS; i++){
            tail[i] = new TupleD(pos);
        }
        speed = new TupleD(0,0);
        accelerator = new Accelerator();        
        accCounter = 1;
    }
    
    // -------------------------------------------------------------------------
    public void move(double dt){
        //
        // update tail
        for (int i = NUM_TAILSEGMENTS-2; i >=0; i--){
            tail[i+1].first = tail[i].first;
            tail[i+1].second = tail[i].second;
        }
        tail[0] = pos;
        //
        // check acc, update if required
        accCounter--;
        if (accCounter <= 0){
            acc = accelerator.updateAcceleration(pos);            
            accCounter = CNT_ACC_UPDATE; 
        }
        //
        TupleD accT = acc.times(0.25);
        speed.addLocal(accT);
        TupleD speedT = speed.times(dt);
        pos.addLocal(speedT);  
        //
        // guarantee max speed limit
        double spd = speed.length();
        if (spd > MAX_SPEED){
            speed.normalizeLocal();
            speed.timesLocal(MAX_SPEED);
            //accCounter = 1;
        }
        // 
        // check side collisions
        boolean bumped = false;
        if (pos.first < 0){
            pos.first = 0;
            speed.first = 0;
            bumped = true;
        }
        else if (pos.first >= Screen.WIDTH){
            pos.first = Screen.WIDTH;
            speed.first = 0;
            bumped = true;
        }
        if (pos.second < 0){
            pos.second = 0;
            speed.second = 0;
            bumped = true;
        }
        else if (pos.second >= Screen.HEIGHT - 1){
            pos.second = Screen.HEIGHT - 1;
            speed.second = 0;
            bumped = true;
        }                 
        if (bumped){
            accCounter = 1;
        }

    }
    
    // -------------------------------------------------------------------------
    public void info(){
        System.out.println("Ball acc:"+acc+"\tspeed: "+speed+"\tpos: "+pos);
    }

    // -------------------------------------------------------------------------
    void draw(Screen screen) {
        int i = 0;
        for (TupleD tpos : tail){
            if ((i-4)%5 == 0){
                screen.plotPoint(tpos);
                screen.plotCircle(tpos,4);                
            }
            i++;
        }
        screen.plotDisc(pos,8);
    }    
}
