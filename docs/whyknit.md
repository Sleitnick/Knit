# Why Knit?

## In Response to AGF

Knit is a response to the underlying issues of [AeroGameFramework](https://github.com/Sleitnick/AeroGameFramework) (AGF). Some problems of AGF:

- Pigeon-holes developers into a specific code structure
- Hard to update and manage
- Hard to migrate existing code
- Not easy to share or distribute services/controllers
- Doesn't support code outside of structure

Knit fixes these problems by having a modular structure. Knit can just be dropped in and used. It can be added to an existing codebase and slowly migrated. Anyone can write a plain module service/controller and distribute it to others.

Knit still holds onto the core mission of AGF: Create an environment where modules of code can freely talk to each other in a structured manner, including crossing the server/client boundary.

## Structure (If you want)

Knit gives developers the ability to create services and controllers, which gives a game structure. However, not all the code has to live in either of these two systems. Code can live alone and still consume services and controllers.

Developers are free to organize codebases in any way.