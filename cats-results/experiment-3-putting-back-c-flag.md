Experiment 3

Can we put back the -c flag we removed from experiments 1 and 2?

Expectation: Yes, because we believe it matches what the builder is outputting
Hope: yes, then we can run potentially a larger numbers of tests. 

Notes:

The test failed. Start was unsuccessful. 

Question: is this a flake? Does it consistently fail? Or is the -c incorrect?

We tried it a second time. 
It failed again. We were able to quickly jump into the logs before the pod crashed as saw this:

/bin/sh: 1: ./catnip: not found

This seems pretty conclusive that our -c flag is not going to work as-is.

...

- Turns out that catnip is pushed some 40 times in all of CATS.
  - and this is all stemming from the fact that the binary buildpack is unavailable with the integrated cnb image (0.0.50-bionic).

Ways forward:
  - option 1: modify CATS to use the Go buildpack when deploying Catnip and not specify the start command.
  - option 2: signal upstream team(s) the need/importance/urgency for the binary buildpack and wait for to become available
  - option 3: have a switch for BOSH-cats vs K8s-cats so that BOSH uses the binary buildpack and k8s uses procfile buildpack



---
(the following are random notes from Jen's attempts to make sense of the new CNB world)
This file seems to answer my question about how we know which CNBs are available in the cloudfoundry/cnb:bionic image:
 https://github.com/cloudfoundry/cnb-builder/blob/master/bionic-order.toml
  - note: the cflinuxfs3 version appears to have a lot more CNBs than bionic, but still no ruby

I followed a tracker ID in one of the commits in the cloudfoundry/cnb-builder repo to arrive at this tracker:
https://www.pivotaltracker.com/n/projects/2398049 (CF Buildpacks Release Engineering)
 - I had no idea there was a CF Buildpacks release engineering team or project. Maybe there isn't? Maybe they just want separate trackers for separate things?
   - wait, what. why are so many of their stories auto-created in the 'done' state.
 - I really just want 30 minutes with Matthew McNew; i just don't get how it all fits together.
 - I'm spinning my wheels here; can we add a Procfile to catnip and have it "just work"?
