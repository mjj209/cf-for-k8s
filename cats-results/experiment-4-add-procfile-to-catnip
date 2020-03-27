Expderiment 4:

If we add a Procfile to catnip, will that make it work with old-school Binary Buildpack and the procfile CNB?

Expectation: This should work. Binary buildpack in the old world == procfile-cnb in the new world, except that the Procfile itself is required.

Experimental setup:
* I've undone the change we previously made to point the Catnip app path to its source.
* I've added a simple Procfile (contents are 'web: ./catnip') as a peer of the catnip binary.
* To be clear, Catnip pushes are now just pushing the binary and the Procfile for this experiment.

Notes:
To start with, keeping our old friendly It block still focused (see experiment 1 notes).
Pushing with a single ginkgo/cats node.

Result:
  Waiting for API to complete processing files...
  Staging app and tracing logs...
  Error staging application: Stager error: Kpack build failed
  FAILED

Logs from the 'detect' container of what I believe is the correct build pod:
  ERROR: No buildpack groups passed detection.
  ERROR: failed to detect: no buildpacks participating

Why did detection fail?
 - Is there a problem with the Procfile I added? (Location, name, contents)
 - Is the procfile-cnb running in this builder?
   - If it is, is it failing to detect?
 - Is the -c messing things up?
    -- unlikely; would expect that to only surface when starting the app.

As part of answering the question on line 27, I wanted to verify that the size of the upload matches the size of the catnip
binary and the Procfile. But that brought up more questions:

Upload output:
  Creating app CATS-1-APP-e3ea52878e23f509...
  Mapping routes...
  Comparing local files to remote cache...
  Packaging files to upload...
  Uploading files...
   168 B / 168 B [=======================================================================================================================================================] 100.00
  % 1s

File sizes:
  js+jr $ ls -lh assets/catnip/bin/
  total 7.8M
  -rw-r--r-- 1 jryan staff   14 Mar 25 16:23 Procfile
  -rwxr-xr-x 1 jryan staff 7.8M Mar 25 16:32 catnip

Possible explanation: resource matching is recognizing that the catnip binary doesn't need to be re-uploaded.

Response to question: is there a problem with the Procfile I added? (Location, name, contents)
- I think I've doubled checked all of these. Procfile seems correct.

Investigating 'Is the procfile-cnb running in this builder?'
- It appears so. I inspected the yaml of the builder in the cf-workloads-staging namespace and saw this under status/builderMetadata:
  - id: org.cloudfoundry.procfile
    version: v1.1.12


Suggestion for experiment 5, if we want to keep digging on this: can we manually push catnip with a procfile and have it work?
- nevermind about full 'experiment 5'. I just did it real quick and got the same error as this experiment.



(pairing)
* We tried using the pack cli instead of kpack to try to replicate this failure.
*   - used the -v flag when running pack to get more output
    `pack build birdrock-jen-test-image --builder cloudfoundry/cnb:0.0.55-bionic --verbose`

Results:

Pulling image [94mindex.docker.io/cloudfoundry/cnb:0.0.55-bionic[0m
0.0.55-bionic: Pulling from cloudfoundry/cnb
Digest: sha256:0a718640a4bde8ff65eb00e891ff7f4f23ffd9a0af44d43f6033cc5809768945
Status: Image is up to date for cloudfoundry/cnb:0.0.55-bionic
Selected run image [94mcloudfoundry/run:base-cnb[0m
Pulling image [94mcloudfoundry/run:base-cnb[0m
base-cnb: Pulling from cloudfoundry/run
Digest: sha256:fb5ecb90a42b2067a859aab23fc1f5e9d9c2589d07ba285608879e7baa415aad
Status: Image is up to date for cloudfoundry/run:base-cnb
Using build cache volume [94mpack-cache-144ddae5d996.build[0m
==> DETECTING
detector ======== Results ========
detector pass: org.cloudfoundry.openjdk@v1.2.14
detector skip: org.cloudfoundry.buildsystem@v1.2.14
detector pass: org.cloudfoundry.jvmapplication@v1.1.12
detector pass: org.cloudfoundry.tomcat@v1.3.15
detector pass: org.cloudfoundry.springboot@v1.2.13
detector pass: org.cloudfoundry.distzip@v1.1.12
detector pass: org.cloudfoundry.procfile@v1.1.12
detector skip: org.cloudfoundry.azureapplicationinsights@v1.1.12
detector skip: org.cloudfoundry.debug@v1.2.11
detector skip: org.cloudfoundry.googlestackdriver@v1.1.11
detector skip: org.cloudfoundry.jdbc@v1.1.12
detector skip: org.cloudfoundry.jmx@v1.1.12
detector pass: org.cloudfoundry.springautoreconfiguration@v1.1.11
detector Resolving plan... (try #1)
detector fail: org.cloudfoundry.jvmapplication@v1.1.12 requires jvm-application
detector Resolving plan... (try #2)
detector fail: org.cloudfoundry.jvmapplication@v1.1.12 requires openjdk-jre
detector Resolving plan... (try #3)
detector fail: org.cloudfoundry.jvmapplication@v1.1.12 requires jvm-application
detector ======== Output: org.cloudfoundry.yarn@0.1.2 ========
detector failed
detector ======== Results ========
detector pass: org.cloudfoundry.node-engine@0.0.158
detector fail: org.cloudfoundry.yarn@0.1.2
detector ======== Output: org.cloudfoundry.npm@0.1.3 ========
detector failed
detector ======== Results ========
detector pass: org.cloudfoundry.node-engine@0.0.158
detector fail: org.cloudfoundry.npm@0.1.3
detector ======== Output: org.cloudfoundry.go-mod@0.0.84 ========
detector no "go.mod" found at: /workspace/go.mod
detector ======== Results ========
detector pass: org.cloudfoundry.go-compiler@0.0.83
detector fail: org.cloudfoundry.go-mod@0.0.84
detector ======== Output: org.cloudfoundry.dep@0.0.89 ========
detector failed detection: no Gopkg.toml found at root level
detector ======== Results ========
detector pass: org.cloudfoundry.go-compiler@0.0.83
detector fail: org.cloudfoundry.dep@0.0.89
detector ======== Output: org.cloudfoundry.dotnet-core-build@0.0.68 ========
detector no proj file found
detector ======== Output: org.cloudfoundry.dotnet-core-conf@0.0.115 ========
detector *.runtimeconfig.json file not found and expecting only a single *.csproj file in the app directory
detector ======== Results ========
detector pass: org.cloudfoundry.node-engine@0.0.158
detector pass: org.cloudfoundry.icu@0.0.43
detector pass: org.cloudfoundry.dotnet-core-runtime@0.0.127
detector pass: org.cloudfoundry.dotnet-core-aspnet@0.0.118
detector pass: org.cloudfoundry.dotnet-core-sdk@0.0.122
detector skip: org.cloudfoundry.dotnet-core-build@0.0.68
detector fail: org.cloudfoundry.dotnet-core-conf@0.0.115
detector ERROR: No buildpack groups passed detection.
detector ERROR: Please check that you are running against the correct path.
detector ERROR: failed to detect: no buildpacks participating


