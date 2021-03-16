#!/usr/bin/awk -f

################################################################################
#                                                                              #
#  10000.awk, a program to compute expectation values in the dice game 10000   #
#  Run on bash with "awk -f 10000.awk" or just "10000.awk"                     #
#  Further information:  http://www.holderied.de/10000/                        #
#                                                                              #
#  Author: Felix Holderied          Date:  2015-03-15                          #
#                                                                              #
################################################################################

BEGIN{
  DEBUG=0;
  # Configuration
  NUMBEROFDICES=6;
  MAXSCORE=1000;
  STEP=50;
  RULEFILE="rules.txt";  
  EXPROLLFILE="expectation_roll.txt";
  EXPRESTFILE="expectation_rest.txt";
  ROLLFILES="rolls0.txt";
  
  # Initialization
  readRules();
  generateRollList(ROLLFILES);
  initExpectationFiles();

  ##############################################################################
  #                                                                            #
  # Main Loop, Generate all Expectations  from 10000, 9950, 9000, ..., 0       #
  #                                                                            #
  ##############################################################################

  for(score=MAXSCORE; score>=0; score-=STEP) {
    print score;
    # Try all selections from 1, 2, ..., 566666, 666666
    # with number of occurences (see rolls1.txt ... rolls6.txt)
    for (var in COUNT) {
       length_tmp=length(var);
       expectation_roll_tmp=expectationRoll(score, var)
       # Write to file
       printf("%d %d %s\n", score, var, expectation_roll_tmp) >> EXPROLLFILE
       # Add to
       expectation_rest_tmp[length_tmp]+=COUNT[var] * expectation_roll_tmp/6^length_tmp;
     }
    for (i=1; i<=NUMBEROFDICES; i++) {
      EXPECTATION[score","i] = expectation_rest_tmp[i];
      # Write to file
      printf("%d %d %.1f\n", score, i, EXPECTATION[score","i]) >> EXPRESTFILE
      # Reset temporary variable
      expectation_rest_tmp[i]=0;
    }
  }
}

################################################################################
#                                                                              #
# Init first rows of two expectation files                                     #
#                                                                              #
################################################################################

function initExpectationFiles(){
  # Expectation depending on score and current roll
  print "# Column 1: Score"           >  EXPROLLFILE
  print "# Column 2: Roll"            >> EXPROLLFILE
  print "# Column 3: Best Action"     >> EXPROLLFILE
  # Expectation depending on score and number of remaining dices
  print "# Column 1: Score"           >  EXPRESTFILE
  print "# Column 2: Number of Dices" >> EXPRESTFILE
  print "# Column 3: Expected Value"  >> EXPRESTFILE
}

################################################################################
#                                                                              #
# Compute best choice and expectation for situation.                           #
#                                                                              #
# Example: score is 200, rolled dices 5523                                     #
#                                                                              #
################################################################################

function expectationRoll(score, roll){
  split(selections(roll), selections_tmp, " ");
  # selections(5523)="5y5y+100 5y+50"
  # selections_tmp[1]="5y5y+100"
  # selections_tmp[2]="5y+50"
  # Init Maximum and best choice (if no selction possible, max=0, best="failed")
  max_tmp=0;
  best_tmp="failed"
  # Loop on all possible selections, e.g. "5y5y+100"
  for (s_tmp in selections_tmp) {
    split(selections_tmp[s_tmp], x_tmp, "+")
    selection_full_tmp  = x_tmp[1];
    # selection_full_tmp="5y5y"
    selection_tmp = selection_full_tmp;
    gsub(/[ny]/, "", selection_tmp)
    # selection_tmp="55"
    score_plus_tmp = x_tmp[2];
    # score_plus_tmp=100
    rest_tmp=length(roll)-length(selection_tmp)
    # rest_tmp=4-2=2
    # If no dices left, rest_tmp=6
    if (!rest_tmp) rest_tmp = NUMBEROFDICES
    # if proofed and new score > max, best choice is end
    if (selection_full_tmp ~ /y/ && score+score_plus_tmp > max_tmp){
      max_tmp  = score+score_plus_tmp
      best_tmp = "select-" selection_tmp "-end"
    }
    # check expectationRest(200+100, 2) (score=300, 2 dices left)
    if (expectationRest(score+score_plus_tmp, rest_tmp) > max_tmp){
      max_tmp  = expectationRest(score+score_plus_tmp, rest_tmp)
      best_tmp = "select-" selection_tmp "-continue"
    }
  }
  # If Expectation > 10000, Expectation=10000
  if (max_tmp > MAXSCORE) max_tmp=MAXSCORE
  # return ...............
  return sprintf("%.1f %s", max_tmp, best_tmp)
}

################################################################################
#                                                                              #
# Function expectationRest(score, rest) reads global variables                 #
# EXPECTATION["200,4"]                                                         #
#                                                                              #
################################################################################

function expectationRest(score, rest){
  # if score > 30000 Expectation=0 (you have to stop between 10000 and 30000)
  if (score>MAXSCORE) return 0;
  # Try to read global variables EXPECTATION["200,4"]
  if (!EXPECTATION[score","rest]) {
    print "EXPECTATION[" score "," rest "] does not exist";
    exit 1;
  }
  # Cut result, if > 10000
  return min(EXPECTATION[score","rest], MAXSCORE);
}

################################################################################
#                                                                              #
# Generate list of sorted rolls with i dices and occurences                    #
# Examples with i=5: 11111 1, 11112 5, ..., 12356 120, 12366 60, ...           #
# Storing to file is only for debugging                                        #
#                                                                              #
################################################################################

function generateRollList(filename){
  # Generate all possible rolls and count them sorted 
  for(numberofdices=1; numberofdices<=NUMBEROFDICES; numberofdices++) {
	# Replace rollsX.txt with rolls1.txt, ... rolls6.txt
    sub(/[0-9]+/, numberofdices, filename);
    print "# Rolls with " numberofdices " dices and occurences" > filename
    for (i=0; i<6^numberofdices; i++) {
      dicessort=sortdices(decode(i, numberofdices))
      if (DEBUG) print i " " decode(i, numberofdices) " " dicessort
      COUNT[dicessort] = COUNT[dicessort] + 1
      }
   }
  # Append every roll to it's certain file
  for (var in COUNT) {
    if (DEBUG) print var " " COUNT[var]
    sub(/[0-9]+/, length(var), filename);
    print var " " COUNT[var] >> filename
  }
  # fflush files (not really necessary)
  for(numberofdices=1; numberofdices<=NUMBEROFDICES; numberofdices++){
	sub(/[0-9]+/, numberofdices, filename);
    fflush(filename);
  }
}

################################################################################
#                                                                              #
# Read rules from file, enumerates them and stored them in three global arrays #                                        #
#                                                                              #
# Example:                                                                     #
#   first accepted line in file is "666   600 n"                               #
#   RULESSELECTION[1] = 666                                                    #
#   RULESSCORE[1]     = 600                                                    #
#   RULESPROOFED[1]  = "n"                                                     #
#                                                                              #
################################################################################

function readRules() {
  NUMBEROFRULES=0;
  while (getline < RULEFILE)
    # print "xxx"
    if ($0~/^ *[1-6]+ +[0-9]+ [ynYN] */){
      #print "c"
      RULESSELECTION[++NUMBEROFRULES]=$1;
      RULESSCORE[NUMBEROFRULES]=$2;
      RULESPROOFED[NUMBEROFRULES]=tolower($3);
      if (DEBUG)
        print NUMBEROFRULES ". " \
              RULESSELECTION[NUMBEROFRULES] " " \
              RULESSCORE[NUMBEROFRULES] " " \
              RULESPROOFED[NUMBEROFRULES];
    }
  # NUMBEROFRULES is now constant and will be used in other functions
  if (!NUMBEROFRULES) {
    print "No valid rules found!"
    exit 1;
  }
}

################################################################################
#                                                                              #
# Recursive function: removedices(alldices, dicestoremove)                     #
#                                                                              #
# Returns throw with selected dices removed                                    #
# in case given dices are not contained, it returns -1                         #
#                                                                              #
# Parameter:                                                                   #
#   dices:         all dices in a throw                                        #
#   dicestoremove: selected dices to remove                                    # #                                                                              #
# Example:                                                                     #
#   removedices("233132", "333") returns "212"                                 #
#   removedices("233132", "422") returns -1
#                                                                              #
################################################################################

function removedices(alldices, dicestoremove) {
  if (!dicestoremove) return alldices
  if (!sub(substr(dicestoremove,1,1), "", alldices)) return -1;
  return removedices(alldices, substr(dicestoremove,2))
}

################################################################################
#                                                                              #
# Recursive function: selections(dices)                                        #
#                                                                              #
# Returns all possible selections, depending on the rules, as string           #
#                                                                              #
# Parameter:                                                                   #
#   dices:    All dices lying unselected on the table e.g. "345441"            #
#                                                                              #
# Example:                                                                     #
#   selections("34544", "", 0, 1) returns "5y444n450 5y50 444n400"             #
#   "5y50" means 5 selected, proofed yes, score 50                             #
#                                                                              #
################################################################################

function selections(dices, selected, sum, rule) {
  if (!rule) rule=1
  if (!dices || rule>NUMBEROFRULES)
    if (selected) return selected "+" sum;
    else          return "";
  if (removedices(dices, RULESSELECTION[rule])==-1)
    return selections(dices, selected, sum, rule+1);
  return selections(removedices(dices, RULESSELECTION[rule]),
                    selected RULESSELECTION[rule] RULESPROOFED[rule] ,
                    sum+RULESSCORE[rule],
                    rule) \
                    " " \
         selections(dices, selected, sum, rule+1);
}

################################################################################
#                                                                              #
# Recursive functions: dices2hist(dices, hist)                                 #
#                      hist2dices(hist, dices, i)                              #
#                      sortdices(dices)                                        #
#                                                                              #
# Returns a histogramm of dices (only works up to 9 dices) or vice versa       #
#                                                                              #
# Parameter:                                                                   #
#   dices:    All dices lying unselected on the table e.g. "345441"            #
#   hist:     Existing histogramm                                              #
#   i:        temporary counter, needed for recursion                          #
#                                                                              #
# Examples:                                                                    #
#   dices2hist(236211, 0)    = 500122                                          #
#   hist2dices(500122, 0, 1) = 112236                                          #
#   sortdices(236211)        = 112236                                          #
#                                                                              #
################################################################################

function dices2hist(dices, hist){
  if (!dices) return hist;
  else        return dices2hist(int(dices/10), hist+=10^(dices%10-1));
}

function hist2dices(hist, dices, i){
  if (!hist)     return dices;
  if (hist%10>0) return hist2dices(hist-1, 10*dices+i, i)
  else           return hist2dices(hist/10, dices, i+1)
}

function sortdices(dices){
  return hist2dices(dices2hist(dices, 0),0,1)
}

################################################################################
#                                                                              #
# Recursive functions: decode(i, numberofdices)                                #
#                                                                              #
# Enumerates rolls: 0 11, 1 12, 2 13 ...  35 66                                #
#                                                                              #
# Parameter:                                                                   #
#   dices:    All dices lying unselected on the table e.g. "345441"            #
#   hist:     Existing histogramm                                              #
#   i:        temporary counter, needed for recursion                          #
#                                                                              #
# Examples:                                                                    #
#   decode(0,2) = 11                                                           #
#   decode(1,2) = 12                                                           #
#                                                                              #
################################################################################

function decode(i, numberofdices) {
  if (i==0 && numberofdices==0) return "";
  else return decode(int(i/6),numberofdices-1) "" i%6+1;
}

################################################################################
#                                                                              #
# functions for maximum and minimum of two values                              #
#                                                                              #
################################################################################

function max(a,b){
  if (a>b) return a
  else     return b
}
function min(a,b){
  if (a<b) return a
  else     return b
}

################################################################################
#                                                                              #
# End                                                                          #
#                                                                              #
################################################################################
