# 10000
Computation of expected Values in Game 10000

Further Information
* https://en.wikipedia.org/wiki/Dice_10000
* https://de.wikipedia.org/wiki/Zehntausend_(Spiel)

Run awk-Skript on shell with
*  ./generate.awk
*  awk -f generate.awk

or use the already computed [expectation_roll.txt](expectation_roll.txt) 

If you user other rules, please try to adapt [rules.txt](rules.txt)

# How to read
The generated file [expectation_roll.txt](expectation_roll.txt) is read as follows.

    250 245 300.0 select-5-end

means: You reached already 250 Points and you roll 245 (three dices). You should write 300 Points and end the roll. Expected Points 300.

    250 266 0.0 failed

means: You reached already 250 Points and you roll 266 Your roll is over, you get 0 Points. Expected Points 0.

    250 333 765.3 select-333-continue

means: You reached already 250 Points and you roll 333. You reached 550 Points and you roll with 6 dices. Expected Points 765.3.

    0 112355 325.3 select-1-continue
    
means; Your first Roll is 112355. You should keep only one 1, and continue with 5 dices. Expected Points 325.3.
