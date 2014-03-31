2squared
========

Big LED trees with blinky blinks


The way the guts work for this is that the LXEngine (http://heronarts.com/lx/api/heronarts/lx/LXEngine.html) has an arbitrary number of LXDecks (http://heronarts.com/lx/api/heronarts/lx/LXDeck.html), it runs them all on each frame and combines the results based on the LXTransition (http://heronarts.com/lx/api/heronarts/lx/transition/LXTransition.html) set for each LXDeck.
