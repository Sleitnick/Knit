# Archival

Knit has been archived and will no longer receive updates.

## Why

This decision is not a matter of maintainability, but rather a shift toward better tooling and resources. Since Knit was released in the summer of 2020, Roblox as a development tool has changed drastically. Changes such as intellisense within Studio's script editor and the introduction of Luau have given developers better tools to build their Roblox experiences.

Due to the nature of Knit's design, these changes put Knit at a significant disadvantage in regard to developer experience. Knit cannot fully benefit from types, and thus does not have good intellisense. While there are workarounds, it forces developers to nearly reinvent Knit altogether.

As such, the best decision is to archive Knit as a project.

## The Missing Roles

As Knit steps away from the Roblox ecosystem, a good question to ask is: What role did Knit serve?

At its core, Knit served two primary roles:

1. Provide a service-like architecture, allowing the construction of top-level structures to help manage a Roblox experience.
2. Provide a seamless networking bridge between the server and client.

Role #1 is easy to replicate, as ModuleScripts themselves can already work in this way out of the box.

Role #2 is harder to replicate. As of this writing, the Roblox "network" tooling ecosystem has been unstable and shifting often. At the end of the day, any networking tool is going to be a wrapper on top of RemoteEvents, UnreliableRemoteEvents, and RemoteFunctions. There is also a challenge with adding types to any networking layer, as Luau's structural typings do not enforce the underlying data. Thus, any hardened types on data coming over the network requires runtime type-checking.

To be fair, type-checking over the network is also a problem in the frontend web development space. TypeScript has helped add types, and open-source libraries such as Zod can help enforce those types by doing runtime type-checking. Knit did not provide runtime type-checking for data over the network, as there were no types to begin with.

In order to preserve the longevity of this writing, no libraries can be offered as a solution, as such libraries come and go. At the end of the day, writing a shallow wrapper around RemoteEvents et. al. is trivial and can be left as an exercise for the reader. Adding generic runtime type checks is harder, but can also be trivial for bespoke setups (e.g. using `assert` on a variable coming over a RemoteFunction to ensure it's a `number` and not something else).

## A Personal Note

I am happy to have offered a tool that has helped so many Roblox developers succeed on the platform. I do not see Knit as a failure, but rather a success. Knit served its purpose, and now it is time to move on.

I do not get sentimental about software. Code is written to solve a problem. When the problems change (or the tools to help solve those problems change), then the code typically needs to change too. Sometimes this means abandoning old solutions in favor of newer ones.

Thank you to everyone who has contributed to Knit, and to all who have supported the project.
