Experiment 5: Use the go buildpack, and unfocus our test

Context: We know we have a problem getting the binary buildpack / procfile-cnb stuff working, but once that's resolved, what other roadblocks might we hit soon after that?

Expectation:  We expect at least that the cf push steps should succeed. Beyond that, we don't really know what might break.


Test setup:
 * Focusing the Lifecycle describe block


 Notes:
 * we forgot to comment out lines 110-120 in cats_suite_test on the first run
   - those check for available buildpacks, and won't work for us

* We ended up cutting this experiment short to try to make the procfile builder work in even a hacky way.
  - that exploration also failed :'(
