package tools;

import jason.asSyntax.Atom;

import java.util.logging.Logger;
import java.util.List;
import java.util.ArrayList;

import java.lang.Math;

import cartago.*;

public class MineMap extends Artifact {

    private static Logger logger = Logger.getLogger(MineMap.class.getName());

    List<Integer[]> golds = new ArrayList<Integer[]>();

    @OPERATION
    public void init() {
        defineObsProperty("n_golds", 0);
    }

    @OPERATION
    public void mark_gold(int x, int y) {
        Integer[] new_pos = {x, y};

        boolean repeated = false;
        for (Integer[] pos : golds) {
            if ((pos[0] == x) & (pos[1] == y)) {
                repeated = true;
            }
        }

        if (!repeated) {
            golds.add(new_pos);

            logger.info("Gold marked at ("+x+","+y+")");

            getObsProperty("n_golds").updateValue(golds.size());
        }
    }

    @OPERATION
    public void get_gold(int ag_x, int ag_y,
                         OpFeedbackParam gold_x, OpFeedbackParam gold_y) {
        if (golds.size() < 1) {
            gold_x.set(-1);
            gold_y.set(-1);
        } else {
            int min_dist = 9999;
            int min_i = 0;
            for (int i=0; i < golds.size(); i++) {
                Integer[] pos = golds.get(i);

                int dist = Math.abs(ag_x - pos[0]) + Math.abs(ag_y - pos[1]);

                if (dist < min_dist) {
                    min_dist = dist;
                    min_i = i;
                }
            }

            Integer[] min_pos = golds.remove(min_i);

            logger.info("telling agent to go for gold at ("+min_pos[0]+","+min_pos[1]+")");

            gold_x.set(min_pos[0]);
            gold_y.set(min_pos[1]);

            getObsProperty("n_golds").updateValue(golds.size());
        }
    }
}
