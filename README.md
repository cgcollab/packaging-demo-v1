# gitops-config

This repository serves to exemplify the ideas presented at GitOpsCon 2023.

----
#### Talk Title & Abstract

[Application Configuration Management at the Edge: Taming Thousands of Deployment Targets](https://cdcongitopscon2023.sched.com/event/1Jp9x)

Configuration management for microservice applications is challenging enough when you’re deploying to just a few production environments.
Imagine deploying different combinations of these microservices to hundreds or thousands of remote production environments—edge locations with glitchy networking, limited resources, and particular configuration needs.
The task grows exponentially harder and it becomes critical to approach it methodically with modern tools and techniques.

In this talk, we’ll dive into the challenges that complicate application configuration management and deployment at the edge.
We’ll also propose an approach for mitigating these challenges using Carvel, a suite of composable tools that can be leveraged for application building, configuration, and deployment to Kubernetes.
----

#### How to Use this Repo

1. Review the [prerequisites](scripts/prerequisites.sh). You can execute the script to satisfy some prerequisites.
2. In a terminal window, go to the home directory of this repo
3Execute the demo:
```shell
./scripts/demorunner.sh scripts/demoscript.sh
```
Hit enter to make the demorunner print the next line to the screen.
When the line is printed, hit Enter again to execute it.
Move though the demoscript in this way using the comments and commands to guide you.

*IMPORTANT* The demo will ask you to confirm the values for a set of environment variables. Make sure the value of the registry is a registry you can reach from your command line (docker pus/pull).
