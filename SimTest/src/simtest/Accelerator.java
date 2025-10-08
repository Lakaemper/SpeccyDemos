package simtest;

/**
 *
 * @author rlaka
 */
public class Accelerator {
    public TupleD currentAcc;
    
    // -------------------------------------------------------------------------
    public Accelerator(){
        TupleD pos = new TupleD(Screen.WIDTH/2, Screen.HEIGHT/2);
        updateAcceleration(pos);
    }

    // -------------------------------------------------------------------------
    public TupleD updateAcceleration(TupleD pos) {
        int region = 40;
        // point inside screen
        int xLeft = (int)Math.max((pos.first - region),0);
        int xRight = (int)Math.min((pos.first + region),Screen.WIDTH);
        int yLeft = (int)Math.max((pos.second - region),0);
        int yRight = (int)Math.min((pos.second + region),Screen.HEIGHT);
        ;
        double x = SimTest.rand.nextInt(xRight-xLeft) + xLeft;
        double y = SimTest.rand.nextInt(yRight-yLeft) + yLeft;
        TupleD p = new TupleD(x,y);
        // diff from pos
        p.subLocal(pos);
        p.normalizeLocal();
        currentAcc = p;           
        return currentAcc;
    }
    
}
