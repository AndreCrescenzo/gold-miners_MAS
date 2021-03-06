// miner agent

{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
{ include("$jacamoJar/templates/org-obedient.asl") }

/*
 * By Joao Leite
 * Based on implementation developed by Rafael Bordini, Jomi Hubner and Maicon Zatelli
 */

/* beliefs */
last_dir(null). // the last movement I did

/* rules */
+!collectgold[scheme(S)]
  <- .print("I'm going to collect the gold!");
     +free.

+!discovermap[scheme(S)] : gsize(_,W,H)
  <- .print("I'm going to search for gold pieces");
     for ( .range(X,1,W-1,6) ) {
       !pos(X,1);
       !pos(X,H-2);
       !pos(X+3,H-2);
       !pos(X+3,1);
     }
     .print("Finished searching").


/* When free, agents wonder around. This is encoded with a plan that executes
 * when agents become free (which happens initially because of the belief "free"
 * above, but can also happen during the execution of the agent (as we will see below).
 *
 * The plan simply gets two random numbers within the scope of the size of the grid
 * (using an internal action jia.random), and then calls the subgoal go_near. Once the
 * agent is near the desired position, if free, it deletes and adds the atom free to
 * its belief base, which will trigger the plan to go to a random location again.
 */

+free : gsize(_,W,H) & jia.random(RX,W-1) & jia.random(RY,H-1)
   <-  .print("I am going to go near (",RX,",", RY,")");
       !go_near(RX,RY).
+free  // gsize is unknown yet
   <- .wait(100); -+free.

/* When the agent comes to believe it is near the location and it is still free,
 * it updates the atom "free" so that it can trigger the plan to go to a random
 * location again.
 */
+near(X,Y) : free <- -+free.



/* The following plans encode how an agent should go to near a location X,Y.
 * Since the location might not be reachable, the plans succeed
 * if the agent is near the location, given by the internal action jia.neighbour,
 * or if the last action was skip, which happens when the destination is not
 * reachable, given by the plan next_step as the result of the call to the
 * internal action jia.get_direction.
 * These plans are only used when exploring the grid, since reaching the
 * exact location is not really important.
 */

+!go_near(X,Y) : free
  <- -near(_,_);
     -last_dir(_);
     !near(X,Y).


// I am near to some location if I am near it
+!near(X,Y) : (pos(AgX,AgY) & jia.neighbour(AgX,AgY,X,Y))
   <- .print("I am at ", "(",AgX,",", AgY,")", " which is near (",X,",", Y,")");
      +near(X,Y).

// I am near to some location if the last action was skip
// (meaning that there are no paths to there)
+!near(X,Y) : pos(AgX,AgY) & last_dir(skip)
   <- .print("I am at ", "(",AgX,",", AgY,")", " and I can't get to' (",X,",", Y,")");
      +near(X,Y).

+!near(X,Y) : not near(X,Y)
   <- !next_step(X,Y);
      !near(X,Y).
+!near(X,Y) : true
   <- !near(X,Y).


/* These are the plans to have the agent execute one step in the direction of X,Y.
 * They are used by the plans go_near above and pos below. It uses the internal
 * action jia.get_direction which encodes a search algorithm.
 */

+!next_step(X,Y) : pos(AgX,AgY) // I already know my position
   <- jia.get_direction(AgX, AgY, X, Y, D);
      -+last_dir(D);
      D.
+!next_step(X,Y) : not pos(_,_) // I still do not know my position
   <- !next_step(X,Y).
-!next_step(X,Y) : true  // failure handling -> start again!
   <- -+last_dir(null);
      !next_step(X,Y).


/* The following plans encode how an agent should go to an exact position X,Y.
 * Unlike the plans to go near a position, this one assumes that the
 * position is reachable. If the position is not reachable, it will loop forever.
 */

+!pos(X,Y) : pos(X,Y)
   <- .print("I've reached ",X,"x",Y).
+!pos(X,Y) : not pos(X,Y)
   <- !next_step(X,Y);
      !pos(X,Y).



/* Gold-searching Plans */

/* The following plan encodes how an agent should deal with a newly found piece
 * of gold, when it is not carrying gold and it is free.
 * The first step changes the belief so that the agent no longer believes it is free.
 * Then it adds the belief that there is gold in position X,Y, and
 * prints a message. Finally, it calls a plan to handle that piece of gold.
 */

// perceived golds are marked on the map so everyone can pick them.
+cell(X,Y,gold) : not gold(X,Y)
  <- mark_gold(X,Y);
     +gold_available.

// once there are golds marked on the map, the agent must go for it
+n_golds(N)
  :  N > 0
  <- -n_golds(N);
     +gold_available.
+n_golds(N) : true
  <- -n_golds(N);
     -gold_available.
    
+gold_available : not carrying_gold & free <- !get_gold.

+!get_gold
  :  pos(AgX,AgY) & not carrying_gold & gold_available
  <- get_gold(AgX,AgY,GdX,GdY);
     -gold(_,_);
     +gold(GdX,GdY).
+!get_gold : not gold_available <- -+free.
+!get_gold <- .print("something went very bad").

@pgold1[atomic]
+gold(X,Y)
  : X < 0 & Y < 0
  <- -gold(X,Y).
/* If the agent passes by any undiscovered gold while heading for another gold
 * picece, it will go for the new one.
 */
@pgold2[atomic]           // atomic: so as not to handle another event until handle gold is initialised
+gold(X,Y)
  :  not carrying_gold
     & not free
     & pos(AgX,AgY)
     & .desire(handle(gold(CurrX,CurrY)))
  <- .drop_desire(handle(gold(CurrX,CurrY)));
     .print("I'll go for gold at (",X,",",Y,") instead.");
     !init_handle(gold(X,Y)).
@pgold3[atomic]
+gold(X,Y)
  :  not carrying_gold & pos(AgX,AgY)
  <- !init_handle(gold(X,Y)).

/* The next plans encode how to handle a piece of gold.
 * The first one drops the desire to be near some location,
 * which could be true if the agent was just randomly moving around looking for gold.
 * The second one simply calls the goal to handle the gold.
 * The third plan is the one that actually results in dealing with the gold.
 * It raises the goal to go to position X,Y, then the goal to pickup the gold,
 * then to go to the position of the depot, and then to drop the gold and remove
 * the belief that there is gold in the original position.
 * Finally, it prints a message and raises a goal to choose another gold piece.
 * The remaining two plans handle failure.
 */

@pih1[atomic]
+!init_handle(Gold)
  :  .desire(near(_,_))
  <- .print("Dropping near(_,_) desires and intentions to handle ",Gold);
     .drop_desire(near(_,_));
     !init_handle(Gold).
@pih2[atomic]
+!init_handle(Gold)
  :  pos(X,Y)
  <- .print("Going for ",Gold);
     -free;
     !!handle(Gold). // must use !! to perform "handle" as not atomic

+!handle(gold(X,Y))
  :  not free
  <- .print("Handling ",gold(X,Y)," now.");
     !pos(X,Y);
     !ensure(pick,gold(X,Y));
     ?depot(_,TX,TY);
     !pos(TX,TY);
     !ensure(drop, 0);
     score;
     .print("Finish handling ",gold(X,Y));
     !!get_gold.

// if ensure(pick/drop) failed, pursue another gold
-!handle(G) : G
  <- .print("failed to catch gold ",G);
     .abolish(G); // ignore source
     !!get_gold.
-!handle(G) : true
  <- .print("failed to handle ",G,", it isn't in the BB anyway");
     !!get_gold.

/* The next plans deal with picking up and dropping gold. */

+!ensure(pick,_) : pos(X,Y) & gold(X,Y)
  <- pick;
     ?carrying_gold;
     -gold(X,Y).
// fail if no gold there or not carrying_gold after pick!
// handle(G) will "catch" this failure.

+!ensure(drop, _) : carrying_gold & pos(X,Y) & depot(_,X,Y)
  <- drop.

// Check if I'm winning
+winner(Ag) : .my_name(Ag)
  <- -winning(Ag);
     .print("I'm winning!").
+winner(Ag) : true
  <- -winner(Ag).

/* end of a simulation */

+end_of_simulation(S,_) : true
  <- .drop_all_desires;
     .abolish(gold(_,_));
     .abolish(picked(_));
     -+free;
     .print("-- END ",S," --").
