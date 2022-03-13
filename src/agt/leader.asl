// leader agent

{ include("$jacamoJar/templates/common-cartago.asl") }

/*
 * By Joao Leite
 * Based on implementation developed by Rafael Bordini, Jomi Hubner and Maicon Zatelli
 */


score(miner1,0).
score(miner2,0).
score(miner3,0).
score(miner4,0).

//the start goal only works after execise j)
//!start.
//+!start <- tweet("a new mining is starting! (posted by jason agent)").

+dropped[source(A)] : score(A,S)
   <- -score(A,S);
      +score(A,S+1);
      -dropped[source(A)];
      .print("Agent ",A," has dropped ",S+1," pieces of gold");
      !update_winner(A,S).

+!update_winner(A,S) : not winning(_,_)
   <- +winning(A,S);
      .print("Agent ",A," is winning");
      .broadcast(tell,winning(A,S)).
+!update_winner(A,S_A) : winning(W,S_W) & S_A > S_W
   <- -+winning(A,S_A);
      .print("Agent ",A," is winning");
      .broadcast(tell,winning(A,S)).
+!update_winner(_,_).
