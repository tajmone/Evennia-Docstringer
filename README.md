# Evennia Docstringer

© Tristano Ajmone, 2015

v. Alpha 1 — 30th March 2015

Released under BSD 2-clause “Simplified” License.

## Introduction

Evennia Docstringer is a Windows standalone application aimed at simplifying and (in future editions) automate the creation of ANSI-formatted MUD-text for Evennia by line-wrapping text at 80 columns (ANSI/Xterm256 tags excluded) and offering a color-preview of how it will look like in MUD output.

## About Evennia

*Evennia* is a modern library for creating [online multiplayer text games][] (MUD, MUSH, MUX, MOO etc) in pure Python. It allows game creators to design and flesh out their games with great freedom. Evennia is made available under the very friendly [BSD license][].

-   [http://www.evennia.com][]

-   <https://github.com/evennia/evennia>

## Features

In it's present Alpha stage it offers the functionality of breaking text, by line-wrapping, into 80-characters long lines — all wrapping calculations are based on the actual characters that will display on the MUD-client screen, so ANSI tags are left out of the calculation.

This comes handy when formatting Cmds autohelp dosctrings: Evennia autohelp generator will take ordinary Python docstrings and extrapolate from them the text that will be shown via the `help` command. Evennia Docstringer will output wrapped text that can be directly pasted as Python docstring into the Cmds module. Output could also be used anywhere custom MUD-text is required.

The user doesn't have to worry about manually wrapping at 80: in Evennia Docstringer the «raw» input and the «docstringed» output are separated; therefore raw text can have long unwrapped lines, and adding and deleting text won't require manually retouching lines to be within 80 characters.

For the time being, 80 columns-wrapping is a fixed value. In future editions it will be customizable via settings.

When wrapping a line that had trailing white-spaces, Evennia Docstringer will carry-on the same spacing on the wrapped lines.

Evennia Docstringer also has a nice color previewer which replicated Evennia's handling of ANSI and Xterm256 tags as close as possible. This feature is quite handy when handling text with lots of ANSI/Xterm256 codes outside of Evennia.

For the moment being, the app offers only clipboard-export functionality, no saving or loading.

## Up-Coming Features

In future editions, this tool will grow with automation in mind: the idea is to manage within a single file more than one docstring, each one being associated with a specific Python class in an external module, so that from a single file it will be possible to handle all the «raw» docstrings of many modules (Cmds, etc.) and inject their formatted version directly into their destination files.

Other upcoming features will relate to the creation/injection of Evennia batch commands and batch codes. This could be used to create server-startup scripts that add custom (non-Cmd related) items to help system.

Also, word-wrapping (hyphened syllabation) options and custom tags for simplifying docstring formatting are on the way — they will be placed in the raw input, and convert into appropriate formatting in the final docstring. Something similar to MarkDown syntax.

Being an open project, ideas are welcomed. So, anything that might be of general help for the creation of MUD-related texts (books, magazines, ecc.) could be proposed and become part of Evennia Docstringer.

For the next updates, the focus will be on file handling: saving, retriving, allowing multiple docstrings per file, associating docstrings to external files, ecc. That achieved, I'll be heading to implement Python modules-injection functionalities. So, stay tuned for updates.

## Supported Tags

The following Evennia ANSI tags/escape-sequences are supported:

-   `{#` and `{[#` where \# stands for any ANSI color (rgybmcwxRGYBMCWX).

-   `{!#` where \# stands for any normal/dark foreground ANSI color (RGYBMCWX).

-   `{###` and `{[###` Xterm colors, where each \# stands for a 0-5 digit.

-   `{n` back to normal mode.

-   `{*` invert foreground and background colors.

-   `{_` tab character (previewed as a single space).

-   `{-` non-strippable whitespace.

-   `{^` blink (taken into account but not previewed).

-   `{h` and `{H` highlight on/off tags.

-   escaped tags, any tag preceded by `{` (eg. `{{r`).

The following tags are not supported:

-   `{/` linebreak (ignored); you shouldn't need that in docstrings anyway.

-   `{lc`, `{lt` and `{le` cliccable-links (ignored); might be implemented in the future.

-   Inline functions. No plans to implement them.

Any invalid tags (eg: `{Q`, `{!r`, `{666`) will simply be ignored and treated as normal text.

For detailed information of supported tags and their use, consult Evennia Wiki page:

-   <https://github.com/evennia/evennia/wiki/TextTags>

## Using and Compiling

Evennia Docstringer comes with both sourcecode and pre-compiled binary file. You don't need to compile it yourself.

It was created using AutoIt version 3.3.12.0, a freeware BASIC-like scripting language:

-   <https://www.autoitscript.com>

The compiled binary doesn't use UPX compression because some anti-virus might give false-positive alerts (see below). Some anti-virus (for example, Gmail's) might complain about the non-packaged version instead.

### UPX Warning

When AutoIt compiles executable files it offers the option to compress them with UPX ([Ultimate Packer for Executables][]). UPX packaged files can be reduced around 40-50% in size. UPX is good, and it's free.

It is wellknown that a number of anti-virus programs give false-positive alerts for UPX-packaged files, and for other packagers too. If after compiling you experience problems with your anti-virus, recompile it trying different compression options.

The reasoning behind these false-positive alarms is that since many hackers use opensource packagers to hide viruses, some anti-virus programs will prevent *any *program compressed with those packagers to run, even though the use of opensource packagers is common good practice in the world of opensource software development. Of course, commercial packagers created by large corporations don't rise false-positives, even though they *might *be carrying malicious code too.

Packaging has nothing to do with malicious contents, it's about compressing binary code, like when you use WinZip. Malicious code is almost always compressed because it tries to avoid fingerprinting, but compressed code is *not *always malicious (on the contrary). There is no direct relation between packaging and malicious-code.

Unfortunately, many programmers had to give-up using good packagers like UPX because of these bad-practices in (rubbish) anti-virus softwares — the problem being that many users think that those antivirus are *better *because they catch viruses that others miss; on the contrary: good antiviruses don't raise false-positives.

So, I apologise for not packaging Evennia Docstringer with UPX. You can still do it yourself though.

For more information:

-   <https://www.autoitscript.com/wiki/AutoIt_and_Malware>

  [online multiplayer text games]: http://en.wikipedia.org/wiki/MUD
  [BSD license]: https://github.com/evennia/evennia/wiki/Licensing
  [http://www.evennia.com]: http://www.evennia.com/
  [Ultimate Packer for Executables]: http://en.wikipedia.org/wiki/UPX
