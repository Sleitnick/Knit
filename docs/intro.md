---
sidebar_position: 1
---

# About

A lightweight framework for Roblox that simplifies communication between core parts of your game and seamlessly bridges the gap between the server and the client.

See the [Getting Started](gettingstarted.md) guide to start using Knit.

## Why Choose Knit?

### Structure (Where you want it)
At the core of Knit are services and controllers, which are just singleton classes that can be easily created. These providers give basic structure to a game. However, not all code is required to live within this sytem. External code in your game can still tie into Knit's services and controllers.

### Server / Client Bridge
Knit bridges the server/client boundary through declarative code that is easy to set up and easy to use. No need to manually create RemoteEvents and RemoteFunctions anymore. Knit handles the core networking for you.

### Framework / Library Hybrid
While advertised as a game framework, Knit straddles the line between a framework and a library. While Knit provides optional structure using services and controllers, developers can choose if and how these structures are utilized. Developers are also responsible for creating the runtime scripts for Knit (i.e. bootstrapping), which allows easy extensibility of the framework.

### For Everyone
Knit is designed to be used by everyone, from professional game studios to someone just diving into Roblox development. For the pros, Knit is available via Wally and can be synced into Studio with Rojo. For the beginners, Knit is available as a standalone model that can be drag-and-dropped into Studio.

### Widely Used
Knit is battle-tested in the Roblox ecosystem, as it has been used by many games across the platform.
