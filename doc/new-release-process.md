Create a new tagged release for tul_cob
===

This document describes how to create a new tag for the tul_cob project.  This
is required when we want to deploy a change to stage or production.

* Go to the release pages on tul_cob: https://github.com/tulibraries/tul_cob/releases
* Click on the "Draft New Release" button on the top right.
* In the "Tag Version" text box, enter the new tag name (ex. v0.7.5)
* Click the target button and select appropriate target branch.
  * Regular deployment: *master*.
  * Hotfix deployment: `hotfix` branch (whatever it's called)
* Fill out the "Release title" input (ex. HotFix(v0.7.5) ) 
* Add the description.
* Save

_Note: If you need to save a draft just make sure that when you come back to it
that you are still pointing the release to the master branch._
