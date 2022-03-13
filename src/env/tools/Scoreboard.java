package tools;

import jason.asSyntax.Atom;

import java.util.logging.Logger;
import java.util.Map;
import java.util.HashMap;

import cartago.*;

public class Scoreboard extends Artifact {

    private static Logger logger = Logger.getLogger(Scoreboard.class.getName());

    int winner_score = 0;
    Map<String,Integer> scores = new HashMap();

    @OPERATION
    public void init() {
        defineObsProperty("winner", new Atom("no_one"));
    }

    @OPERATION
    public void score() {
        String agent_name = getCurrentOpAgentId().getAgentName();

        int score = 1;
        if (scores.containsKey(agent_name)) {
            score = scores.get(agent_name) + 1;
        }
        scores.put(agent_name, score);
        logger.info(agent_name+" scores!");

        if (score > winner_score) {
            winner_score = score;
            getObsProperty("winner").updateValue(new Atom(agent_name));
            logger.info(agent_name+" is ahead with "+score);
        }
    }
}

