Experiment 2:

Same context as the beginning of experiment 1, except this time we will first enable the diego_docker feature flag.

Copied over experiment setup:
Try to figure out a low hanging fruit of what may be causing lots of test failure by digging into the failure of a simple cf push test.

* Need to identify a good simple test.
* Run that test
* Dig in.

Running line 75 in lifecycle.go, since it seems to just pushing a simple go app. We first enable the feature flag.

Expectations: we expect this to succeed.

Notes:
Cleaning up from experiment 1 by deleting all the orgs (and thus the apps).
We saw a failure again, similar to what we saw at the beginning of experiment 1 (waiting for an app to start, didn't start)
 - during that time, we saw a pod blip into existance in cf-workloads

To reduce the amount of noisy logging, we went from 7 nodes to running CATs serially.
 - this time, the test actually passed!

 Question: does tests in parallel somehow negatively affect our cf-for-k8s pushes?

