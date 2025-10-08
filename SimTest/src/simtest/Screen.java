/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package simtest;

import java.awt.Color;
import java.util.HashSet;
import java.util.Set;
import simplegui.*;
/**
 *
 * @author rlaka
 */
public class Screen {
    public static final int WIDTH = 256;
    public static final int HEIGHT= 192;
    private static final int scale = 4;
    SimpleGUI sg;
    
    public Screen(){
        sg = new SimpleGUI(WIDTH*scale, HEIGHT*scale, false);
        sg.centerGUIonScreen();
        sg.setBackgroundColor(Color.yellow);        
        sg.setColorAndTransparency(Color.black, 1.0);
        sg.setAutoRepaint(false);
    }
    
    public void plotPoint(TupleD point){
        TupleD p = point.times(scale);        
        TupleD offset = new TupleD(scale/2, scale/2);
        p.subLocal(offset);
        sg.drawFilledBox(p.first, p.second, scale, scale);
    }

    void plotCircle(simtest.TupleD point, int sz) {
        TupleD p = point.times(scale);        
        TupleD offset = new TupleD(scale/2*sz, scale/2*sz);
        p.subLocal(offset);
        sg.drawEllipse(p.first, p.second, scale*sz, scale*sz);
    }
    
    void plotDisc(simtest.TupleD point, int sz) {
        TupleD p = point.times(scale);        
        TupleD offset = new TupleD(scale/2*sz, scale/2*sz);
        p.subLocal(offset);
        sg.drawFilledEllipse(p.first, p.second, scale*sz, scale*sz, Color.RED,0.3, "");
    }
    
}
