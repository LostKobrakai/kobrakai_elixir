---
title: Elixir Deployment Approaches
headline: "Elixir Deployment Approaches: An Overview on how to handle building a project"
draft: true
tags: 
  - blog
  - programmierung
language: EN
---
Deployment of elixir projects is often seen as difficult and complex. I've written a [previous blog post](https://lostkobrakai.svbtle.com/elixir-deployments) on how and why this might be the case. In this blogpost I'll simply try to give an overview of various approaches one can take and when they might be suitable to pick up.

---

## How to build a production ready artefact(s)

Going from source code to production does most often require an compile step. For elixir projects this might be `mix release` to build a release, but also things like running an asserts pipeline to build js/css files in phoenix. This is quite common to many projects, but there's one additional complication for `mix release`: It needs to run in an environment matching production in OS, native libraries and such.

### Custom Scripting

The most flexible and customizable option, but also possibly not the most approachable. Basically one would create some scripts, which trigger all the task, which need to happen as part of a build. Either by creating full on shell scripts to do things or shell commands as part of e.g. a CI setup or scripts for tools like ansible/chef/….

*Benefits*
- Easy to customize
- Easy to port

*Downsides*
- Often quite custom / one off ways to handle things
- One does need to care that the build system and production systems match

### Buildpacks

Many PaaS solutions use buildpacks to handle common tasks in preparing a project (usually checked out from git) for production usage. Those buildpacks run in the same environment as what will later become the running server. 

*Benefits*
- Many buildpacks are already available for common tasks
- Quick to get started
- No need to worry about matching build and prod system

*Downsides*
- Customization is more complex to deal with
- Only usable for systems supporting buildpacks

### Docker

Docker is similar to how buildpack based PaaS work. One can setup an containers matching their production system, whose are feed the source code and then handle the building. One can use Docker just to handle the task of building, or using multi-stage builds to also store the resulting files into an docker image for execution. 

*Benefits*
- (multi-stage) Portable between anything supporting docker images
- (multi-stage) Less need to worry about matching build and prod system
- Customizable

*Downsides*
- Handling docker in production on own servers isn't everyones cup of tea

---

## Where to use those approaches

### Locally

If one does happen to run the same system locally as in production then building can happen using shell scripts directly on ones computer. 

The other alternative is using a virtualized machine to mimic production, where Docker is the common solution for.

Ship the built files to any server being able to handle them.

*When to use*
- One doesn't want to setup anything else besides the prod server
- One is fine with handling tasks manually, which can be automated in CI/CD

### Prod. System

One can use the production system itself with scripts to build a project. This is usually not recommended as it puts additional load on your production system – and compilation might swallow considerable performance – but might be fine under the right circumstances.

*When to use*
- One doesn't want to setup anything else besides the prod server
- Prod server can handle the additional load

### CI/CD Systems

This is the way I recommend the most. 

CI systems are often container if not Docker based, so you can make the executing build system match your production ones. Additionally you could also use Docker within the container your CI provides.

With GitHub/GitLab offering free CI solutions today it's not even that much a question about cost anymore.

Shipping to production can be handled by this as well.

*When to use*
- One can't go wrong with CI/CD, so it's a safe default choice
- Flexible, but might still have means of sharing common task handling

*Providers*
- [GitHub Actions](https://github.com/features/actions)
- [GitLab CI](https://docs.gitlab.com/ee/ci/)
- Any other CI/CD solution

## PaaS

If you don't want to deal with server management at all PaaS are a great solution. There are ones, which support buildpacks as well as ones supporting lower level tooling like bash scripts. 

*When to use*
- Easy to start with
- No need to deal with servers
- Buildpacks provide needed functionality

*Providers*
- [Gigalixir](https://www.gigalixir.com/) (Buildpack based)
- [Heroku](https://www.heroku.com/) (Buildpack based)
- [Render](https://render.com/) (Bash-script based)

## Custom Setup

The above are basically stepping stones to get up and running. This is by no means an exhaustive list and more complex setups might need more tooling and even combinations of the above. 

---

As this post shows there are many ways to deal with building an elixir project for production usage. I hope this will at least help decide people of which way they want to go and get started.