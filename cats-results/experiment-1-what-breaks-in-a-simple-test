Experiment 1:

Try to figure out a low hanging fruit of what may be causing lots of test failure by digging into the failure of a simple cf push test.

* Need to identify a good simple test.
* Run that test
* Dig in.


Running line 75 in lifecycle.go, since it seems to just pushing a simple go app.

Expections: we expect this to succeed.


Outcome: failure with this text
Staging app and tracing logs...
Error staging application: Stager error: Kpack build failed
FAILED


Notes from investigation:
3/24/20
* hard to debug with so many other failed pods and builds in cf-system from previous cats runs
 - manually deleting the builds and pods was only temporary -- they came back
 - we're hoping that deleting the apps backing those builds (via cf delete-org) will prevent builds from being recreated.
 - that didn't fix it; the builds still came back. we're confused.
 - john remembers hand deleting the build pods in the past and having them stay dead.
 - ???
 - we don't want to get distracted by this.
 - will try to just delete cf-system (and postgres?)
 - trying to delete cf-system and cf-db; the postgres PVC timed out deleting on fresno. Dunno why. Claimed vashon

* we deployed to the vashon cluster and then ran the same single test as mentioned above.
* we modified the catnip app location in the cats settings, so that Assets.Catnip points to the source code, not the compiled binary.
* we saw it succeed during staging, but timed-out while waiting to start. We suspect this is due to the -c flag given to cf push: `cf push -c ./catnip`.
* we removed the `... -c ` and tried again.  Same symptoms.
* suggestion: try `cf push` manually with the same asset and see what's different (and get away from a timeout).

3/25/20
* note: we released fresno from its misery. We ran `kapp delete -a cf --dangerous-something-or-other`. (Didn't double check that it's all cleaned up; not our top priority)
(jen solo notes)
* logging into the vashon env via cf CLI: cf auth admin $(yq -r .cf_admin_password /tmp/vashon-cf-values.yml)
* now going to try a manual cf push similar to the test we're isolating in CATs.
* test body:
     Expect(cf.Cf("push",
          appName,
          "-b", Config.GetBinaryBuildpackName(),
          "-m", DEFAULT_MEMORY_LIMIT,
          "-p", assets.NewAssets().Catnip,
          "-d", Config.GetAppsDomain()).Wait(Config.CfPushTimeoutDuration())).To(Exit(0))
 
        Eventually(func() string {
          return helpers.CurlAppRoot(Config, appName)
        }).Should(ContainSubstring("Catnip?"))
* going to avoid using a lot of these flags for the moment, can add back once we're on stable ground and see if one of the flags is the problem.
* creating org o and space s for quick typing (cf co o && cf t -o o && cf create-space s && cf t -s s)
* manual equivalent would be: cf push testapp -p ~/workspace/cf-acceptance-tests/assets/catnip
* CLI has been waiting at 'Staging app and tracing logs...' for a while (4 min); from past experience, i know this isn't about waiting for logs, but waiting for the app to start
  - nothing in the cf-workloads namespace
  - trying to look at the Eirini logs (in the opi container of the cf-system/eirini pod), but the logs don't go back very far at all in time.
    - did eirini drop or lose its old logs? is this just a k9s or k8s thing? or did eirini crash and restart? -- this last question is easy to check
      - eirini pod has had 0 restarts, according to k8s. No clue why its logs only go back 2 seconds.
* random thought: it's tough to debug situations like this with two cloud controllers. We don't need HA for our test envs. Maybe we should only deploy 1 CC? at least on vashon, for right now, that is probably uncontroversial.
* After 5 minutes, the CLI timed out waiting for the app to start. This is the CLI's full error message:
    Start app timeout

    TIP: Application must be listening on the right port. Instead of hard coding the port, use the $PORT environment variable.

    Use 'cf logs testapp --recent' for more information
    FAILED
* I'm going to try this again, but watch cf-workloads while the push happens. Maybe there's a pod that tries to start up, but quickly crashes?
 -- first attempt wasn't really a fair test -- i reused the app name, which may surface different bugs.
* At first I thought the CLI's "tip" above was unrelated to what we're seeing, but now I'm wondering... I think the bug that makes Eirini ignore custom set ports for 
  docker images will also happen for kpack-lifecycle apps. What port is catnip listening on? I think it may need to be 8080?
   -- catnip doesn't have a default port. If no `PORT` environment variable is set, it seems like it would crash.
    --- but i didn't see it starting up in cf-workloads at all. :Hmmm:

(john solo notes)
* Great notes, Jen, thanks!  Picking up from where she left off...
* re: catnip startup -- I notice that there's a line of console output/logging where catnip indicates which port it is listening on... but I don't see that line in any logs that I've viewed.
* I'm at a bit of a loss.  I know I want to know more about how CAPI is behaving.  Is it successfully requesting that Eirini schedule this app?
  - I'm tailing all logs from all pods named "capi-%" and then re-attempting the `cf push`

(pairing!)
* after lunch, let's break down the cf push command to its subcommands:
  cf stage -v (for an already pushed app)
  cf start -v

(jen solo)
preparing for 'cf stage' and 'cf start'
scaled down capi to one instance (via 's' in deployments view in k9s)
delete older builds? or can we ID which one the new one is?
 - didn't delete older builds; i'll just watch carefully during the stage
runnign 'cf stage nodeapp -v'
 - stage is not a command; trying restage
 - hm, maybe restage isn't implemented yet. got a 500 error from log cache; CAPI 'succeeded' but i don't see any new builds
jumping right ahead to 'cf start' because we believe staging actually worked the first time around for 'nodeapp'
    cf start nodeapp
    Starting app nodeapp in org o / space s as admin...
    App nodeapp is already started
(nothing was in cf-workloads)

    cf restart nodeapp
    Restarting app nodeapp in org o / space s as admin...

    Stopping app...

    Staging app and tracing logs...
    The app is invalid: VCAP::CloudController::BuildCreate::StagingInProgress
    FAILED

Trying to curl a bunch of relationship links listed at `cf curl /v3/apps/9a9d12b3-11e0-4da6-bcab-1380585aeb15/`
 - inspecting and seeing if anything jumps out about the staging status
 - didn't see anything exposed on the API indicating that the staging is still in process.

I feel like I'm poking around the edges of a black box. Want to take a moment to review the capi code to add the kpack lifecycle. May help with debugging and understanding.
cloned cloud_controller_ng into `~/workspace` on John's machine.

(pairing!)
time to downshift
we know smoke tests are working in stability CI; do smoke tests work on our env?

WOW

as we ran smoke tests, we were watching the cf-workloads namespace. When we started the test, there were no pods in that namespace.
When the test started running, we saw FOUR pods appear in the list. The following four pods appeared:
catnip-...
cf-for-k8s-smoke-1-app-343592c7c609c55f-...
testapp-...
testapp2-..

Couple of observations:
* only one of the two smoke test apps are showing up here. We're still "waiting" for the smoke tests themselve to complete
* three of the apps are things we tried pushing earlier today. However, our friend 'nodeapp' is not there. The others from today are all there.


Connor from CAPI suggested that it may be that our smoke tests turned on the diego_docker feature flag, and we didn't have it on before.
- THIS MAKES SO MUCH SENSE
- AND IS SO SAD.


Conclusion of this experiment:
- You need diego_docker feature flag turned on before running CATs. The error won't be obvious if it's off.


