---
title: Are elixir deployments really that hard?
tags:
  - blog
  - programmierung
language: EN
---

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I&#39;ve thought that <a href="https://twitter.com/rails?ref_src=twsrc%5Etfw">@rails</a> deployment on a non-Docker or non-Heroku production server was tricky. But that is nothing compared to <a href="https://twitter.com/elixirphoenix?ref_src=twsrc%5Etfw">@elixirphoenix</a>.<br><br>A million buggy how-tos and deployment tools. Not a single one works. Not a single README works. Always something &quot;small&quot; is missing.</p>&mdash; Stefan Wintermeyer (@wintermeyer) <a href="https://twitter.com/wintermeyer/status/1239938792536117248?ref_src=twsrc%5Etfw">March 17, 2020</a></blockquote>

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">At the end of a two day hunt for a <a href="https://t.co/nY1mnbHhzA">https://t.co/nY1mnbHhzA</a> like tool I ended up with the advise of pros in an Elixir Slack channel to &quot;just write a Bash script which glues everything together&quot;.</p>&mdash; Stefan Wintermeyer (@wintermeyer) <a href="https://twitter.com/wintermeyer/status/1239938793681096704?ref_src=twsrc%5Etfw">March 17, 2020</a></blockquote>

Thoughts like this are not really rare for people new to elixir. And they're not totally wrong in their assessment either. Doing such a comparison however expects that a similar level of "just handle this for me" is actually possible for elixir tools to provide and if so that it's a good idea to do so. This is an attempt in clearing up a bit of the missing pieces in comparing elixir deployment to deployment tools of other languages.

## What is deployment

Deployment in the context of elixir usually refers to the need of talking elixir source code usually in a mix project and bringing it's functionality to a server somewhere on the internet and running the project on it.

In interpreted languages – like ruby – this is usually done by having the server use the language's runtime and shipping source code directly to the server. The source code is then executed using the installed runtime.

The same can be done in elixir as well. With erlang, elixir and mix on the server one _can_ run a mix project with `MIX_ENV=prod mix …`. This is usually not how deployment is handled in the community though. People tend to use releases, which I'll discuss in more detail later.

First I'd like to separate "deployments" up into a few sub tasks, which need to be done as part of a deployment. A few key tasks are:

- compile source files to the actual files pushed to a server
  (prim. language as well as assets like js/css)
- upload files to a server
- start/stop logic of running instance on the server
- keep service running on the server in case of failures

This is not meant to be a comprehensive list of everything a deployment handles, but those are tasks useful to keep in mind for the rest of the blog post.

## Why releases and what's the matter with them

Releases on the beam refer to a set of compiled files/folders, which form a self-contained artifact specifically for deployments. Often it comes as a tar archive, which can be unarchived on a production server and be started there using plain old executable shell scripts.

Self-contained for releases means it contains the beam vm, all applications of a project with all their compiled beam files, priv folders and scripts to start/stop things. The server itself doesn't need erlang/elixir installed at all (unless bundling of erts files is disabled). No need to version control a language runtime.

In a mix project a release is built by running `mix release`. There's [great documentation](https://hexdocs.pm/mix/Mix.Tasks.Release.html) available on how it works, so I won't go into much detail here. For phoenix projects make sure to also consult [its documentation](https://hexdocs.pm/phoenix/releases.html).

How does this relate to the difficulty of kitchen sink deployment tools especially if we seem to have a great way to bundle everything up neatly?

The answer is that while self-contained a release is build for a [specific system](https://hexdocs.pm/mix/Mix.Tasks.Release.html#module-requirements). Things like OS, various system libraries as well as certain NIF resources need to be the same on the system building a release as on the system running it.

To fulfill this requirement there are essentially three options:

1. Make the development system match production
2. Have an intermediate system (e.g. vagrant/docker/CD systems) match production
3. Build the release on the production server.

Option 1 and 3 are not really popular. Often people are not running their server's flavor of linux in development and a production server should not be bothered with compiling releases, but with running them. There exist tools using those options, but they often don't have many users and are not quick to pick up in a general sense.

Option 2 is the one, which most people implement, but it highly depends on the infrastructure one has available. With a CI/CD environment ready it's usually quite simple to have it automate a docker container, which mimics production, to build a release. If that's not the case it might be possible to run docker locally to do the same. If docker is a problem then there might be other means to have a build system running locally or remote to do the job. But one needs to find some way to have a system for building the release.

Automating Option 2 is quite difficult for a generalized tool. Without limiting to a certain kind of project, infrastructure and possibly other constraints it's not possible to generalize what needs to be done where.

## Deployment: The other tasks

There is quite some complexity in infrastructure involved in getting a release to be build, once this is handled though a `mix release` should do the job – with phoenix one additional command might be needed to trigger the assets pipeline. But what about the other parts of deployment listed in the initial section of the blogpost. How is the release uploaded, started, stopped, restarted, ….

This is where erlang traditionally as well as elixir don't need to be involved anymore. Any system, which can handle plain shell scripts, can handle releases. From bash scripts to ansible or heck even capistrano. On the server there is upstart, initd, systemd, docker and further tools to handle the lifecycles of services. There are a variety of solutions out there. One just has to choose which one to employ.

In professional environments this is also the place where integration with existing tooling becomes relevant. There might be multiple projects of various languages to be handled. Therefore general purpose tools are actually a good investment and might even be a requirement.

## Conclusion

The last two sections hopefully explain a bit why there are few batteries included tools for handling complete deployments in elixir. The complex, elixir-specific parts are mostly in replicating ones specific server setup – there are e.g. docker solutions for certain os/architectures, but not for others – and the parts, which can be generalized are actually better handled by more general server management/deployment tooling, which can be used in language agnostic manner.

For most companies deployment tools, CI/CD Pipeline and servers are already present, so it's often more a matter of adjusting the elixir workflow to work within those existing systems than it's a case of a tool being able to prescribe how deployment has to work with elixir and doing everything in its way.

Sadly this means one-off and less infrastructure heavy deployment solutions are currently not supported out of the box to the degree one might hope for. Falling back to installing elixir on the server and running source code can be a solution for those kinds of cases though.
