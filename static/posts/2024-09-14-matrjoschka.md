---
title: Matrjoschka of phoenix communication
tags:
  - blog
  - programmierung
  - backend
language: EN
excerpt: |
  Shining some light on how phoenix built additional layers of abstraction on top
  of the primitives of message passing on the BEAM.
---

Phoenix, the powerful Elixir web framework, is renowned for its real-time capabilities.
But with terms like Channels, Presence, and PubSub floating around, it's easy for
newcomers to feel overwhelmed. What exactly do these components do, and how do they
relate to each other?

If you've found yourself puzzling over the differences between Phoenix Channels and PubSub,
or wondering when to use which feature, you're not alone. In this post, we'll demystify
Phoenix's real-time toolbox, breaking down each component and its role in building
dynamic, responsive applications.

From the foundational PubSub server to the high-level abstractions of Channels and
Presence, we'll explore how these layers work together and when to leverage each
one. By the end of this guide, you'll have a clear understanding of Phoenix's
real-time architecture, empowering you to choose the right tools for your next project.

## Smallest Building Block: `Registry`

Before we dive into Phoenix's real-time features, let's start with a fundamental
building block: the `Registry` module. You might wonder why we're beginning with
an Elixir module in a post about Phoenix. The answer lies in the evolution of
Phoenix's PubSub system.

The `Registry` module was added to [Elixir 1.4](https://github.com/elixir-lang/elixir/commit/35a793dfe6a1d563d9a565a1ce939389c5402dab)
(2016) after being [extracted and extended](https://groups.google.com/g/elixir-lang-core/c/NZMBjxD0UjY/m/DXCcRRqVAgAJ)
based on code within the `Phoenix.PubSub` codebase. This was right after José and Chris
had worked on scaling Phoenix to for the famous [2 Million Websocket Connections](https://www.phoenixframework.org/blog/the-road-to-2-million-websocket-connections)
benchmark.

Interestingly, it took almost three more years for phoenix_pubsub to actually
adopt `Registry` in its [2.0 version](https://github.com/phoenixframework/phoenix_pubsub/commit/c05d47f6411d81f3cd94d53607848b5195239c4f#diff-94f1a17aeeeaf082667bcae2a464afbf924e26394266babb2ec709d78dade121).

With the history out of the way – what is `Registry` for?

`Registry` provides local process registration on a beam node. One part of that
is the `keys: :duplicate` setting, which allows many processes to register under
a single key. Using `Registry.dispatch` those registrations can be used to
implement [node local PubSub](https://hexdocs.pm/elixir/Registry.html#module-using-as-a-pubsub).

`Registry` is used that way by many tools not just within Phoenix. One example
would be (`PropertyTable`)[https://hexdocs.pm/property_table/PropertyTable.html]
often used in nerves systems.

<svg class="excalidraw" version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 147 148" width="294" height="296">
  <g stroke-linecap="round" transform="translate(10 10) rotate(0 63.5 64)"><path d="M31.75 0 C49.81 -0.08, 72.38 -1.33, 95.25 0 M31.75 0 C52.75 0.21, 72.34 -0.86, 95.25 0 M95.25 0 C116.44 1.56, 126.91 11.96, 127 31.75 M95.25 0 C117.22 -2.06, 126.77 9.26, 127 31.75 M127 31.75 C126.26 48.5, 128.1 64.61, 127 96.25 M127 31.75 C126.75 56.33, 125.97 81.16, 127 96.25 M127 96.25 C125.48 118.48, 115.31 126.6, 95.25 128 M127 96.25 C128.6 116.46, 118.7 126.55, 95.25 128 M95.25 128 C81.37 130, 68.23 128.79, 31.75 128 M95.25 128 C78.7 127.62, 63.85 127.91, 31.75 128 M31.75 128 C12.28 126.14, 1.16 118.41, 0 96.25 M31.75 128 C8.29 129.56, -0.97 118.66, 0 96.25 M0 96.25 C1.2 75.79, 0.37 58.61, 0 31.75 M0 96.25 C-0.19 78.96, 0.85 62.83, 0 31.75 M0 31.75 C1.34 10.56, 11.4 0.79, 31.75 0 M0 31.75 C0.63 10.19, 11.34 -1.19, 31.75 0" stroke="currentColor" stroke-width="2" fill="none"></path></g><g transform="translate(31.620000139872218 61.5) rotate(0 41.87999986012778 12.5)"><text x="41.879999860127775" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Registry</text></g>
</svg>

## Building on Registry: `Phoenix.PubSub`

After understanding the local capabilities of `Registry`, let's explore how Phoenix
scales this concept across multiple nodes with `Phoenix.PubSub`. While Registry
excels at managing processes within a single node, `Phoenix.PubSub` extends this
functionality to enable cluster-wide communication in distributed Phoenix applications.

`Phoenix.PubSub` acts as a bridge between nodes, allowing `Registry` instances on
individual nodes to forward messages to local subscribers – while also sharing
broadcasted messages with the rest of the cluster. This is crucial for applications
that need to scale horizontally across multiple servers. Since version 2.0,
`Phoenix.PubSub` is using OTP's process groups (`:pg`) module for its
distributed functionality.

`Registry` and `Phoenix.PubSub` form the backbone of Phoenix's real-time features.

<svg class="excalidraw" version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 40 485 120" width="970" height="240">
  <!-- svg-source:excalidraw -->
  <g stroke-linecap="round" transform="translate(10 10) rotate(0 232.5 92.5)"><path d="M32 0 C135.87 -1.28, 242.06 -1.73, 433 0 M32 0 C163.43 1.97, 295.21 1.77, 433 0 M433 0 C456.24 -0.54, 466.33 11.1, 465 32 M433 0 C455.05 -1.31, 466.97 10.14, 465 32 M465 32 C466.55 75.61, 466.6 115.25, 465 153 M465 32 C464.05 74.53, 463.24 116.37, 465 153 M465 153 C464.41 173.37, 454.7 186.2, 433 185 M465 153 C464.6 175.27, 456.16 184.99, 433 185 M433 185 C293.96 187.16, 156.58 185.46, 32 185 M433 185 C344.3 183.22, 255.91 182.95, 32 185 M32 185 C12.38 186.98, 0.18 176.13, 0 153 M32 185 C9.52 184.32, -0.53 172.7, 0 153 M0 153 C-0.95 118.45, 0.35 86.01, 0 32 M0 153 C0.05 123.13, -0.03 92.11, 0 32 M0 32 C-1.13 11.6, 10.28 -1.93, 32 0 M0 32 C2.08 9.66, 11.34 -0.14, 32 0" stroke="currentColor" stroke-width="2" fill="none"></path></g><g transform="translate(204.41333363850913 77.5) rotate(0 38.08666636149087 25)"><text x="38.086666361490884" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Phoenix</text><text x="38.086666361490884" y="42.62" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">PubSub</text></g><g stroke-linecap="round" transform="translate(51 40) rotate(0 63.5 64)"><path d="M31.75 0 C49.81 -0.08, 72.38 -1.33, 95.25 0 M31.75 0 C52.75 0.21, 72.34 -0.86, 95.25 0 M95.25 0 C116.44 1.56, 126.91 11.96, 127 31.75 M95.25 0 C117.22 -2.06, 126.77 9.26, 127 31.75 M127 31.75 C126.26 48.5, 128.1 64.61, 127 96.25 M127 31.75 C126.75 56.33, 125.97 81.16, 127 96.25 M127 96.25 C125.48 118.48, 115.31 126.6, 95.25 128 M127 96.25 C128.6 116.46, 118.7 126.55, 95.25 128 M95.25 128 C81.37 130, 68.23 128.79, 31.75 128 M95.25 128 C78.7 127.62, 63.85 127.91, 31.75 128 M31.75 128 C12.28 126.14, 1.16 118.41, 0 96.25 M31.75 128 C8.29 129.56, -0.97 118.66, 0 96.25 M0 96.25 C1.2 75.79, 0.37 58.61, 0 31.75 M0 96.25 C-0.19 78.96, 0.85 62.83, 0 31.75 M0 31.75 C1.34 10.56, 11.4 0.79, 31.75 0 M0 31.75 C0.63 10.19, 11.34 -1.19, 31.75 0" stroke="currentColor" stroke-width="2" fill="none"></path></g><g transform="translate(72.62000013987222 91.5) rotate(0 41.87999986012778 12.5)"><text x="41.879999860127775" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Registry</text></g><g stroke-linecap="round" transform="translate(309.5 40) rotate(0 63.5 64)"><path d="M31.75 0 C47.85 0.37, 69.02 -0.73, 95.25 0 M31.75 0 C57.21 0.42, 81.31 1.06, 95.25 0 M95.25 0 C116.3 -1.57, 125.73 8.73, 127 31.75 M95.25 0 C118.34 -0.73, 127.81 9.29, 127 31.75 M127 31.75 C126.74 50.52, 128.69 66.4, 127 96.25 M127 31.75 C127.03 48.34, 125.54 65.61, 127 96.25 M127 96.25 C126.81 118.05, 118.12 126.91, 95.25 128 M127 96.25 C126.16 116.94, 115.64 127.25, 95.25 128 M95.25 128 C80 127.68, 65.35 127.64, 31.75 128 M95.25 128 C77.25 127.78, 57.85 128.83, 31.75 128 M31.75 128 C9.11 126.56, 1.75 118.32, 0 96.25 M31.75 128 C8.94 129.25, -0.79 115.17, 0 96.25 M0 96.25 C0.82 75.09, -0.83 56.01, 0 31.75 M0 96.25 C-0.31 80.19, -0.01 63.09, 0 31.75 M0 31.75 C-0.07 9.35, 11.03 -0.05, 31.75 0 M0 31.75 C0.48 11.07, 10.97 1.89, 31.75 0" stroke="currentColor" stroke-width="2" fill="none"></path></g><g transform="translate(331.1200001398722 91.5) rotate(0 41.87999986012778 12.5)"><text x="41.879999860127775" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Registry</text></g>
</svg>

## Including external clients: `Phoenix.Channel`

With `Phoenix.Channel`s the scope of the PubSub communication is extended again,
this time adding external clients into the mix. Typically, these external clients
are users of Phoenix websites, with their browsers establishing connections to
Elixir nodes via WebSockets or long-polling.

However, the power of Channels isn't limited to web browsers. The Channel
abstraction is protocol-agnostic, meaning it can be implemented on top of
various transport protocols. This flexibility allows Phoenix applications to
communicate with a wide array of clients - mobile apps, IoT devices, or even
other server applications. Any client able of speaking the chosen transport
protocol can participate in the real-time communication.

One good example in the IoT / other server space is
[NervesHub](https://www.nerves-hub.org/), which implements remote IEx shells for
embedded devices, as well as distributing firmware updates, over Channels.

Channels are the final layer of extension on the PubSub side of Phoenix. Next
we'll look at two related features of Phoenix, which make use of PubSub to enable
more complex functionality in Phoenix.

<svg class="excalidraw" version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 75 531 201" width="1062" height="402">
  <g stroke-linecap="round" transform="translate(34 29) rotate(0 232.5 92.5)"><path d="M32 0 C135.87 -1.28, 242.06 -1.73, 433 0 M32 0 C163.43 1.97, 295.21 1.77, 433 0 M433 0 C456.24 -0.54, 466.33 11.1, 465 32 M433 0 C455.05 -1.31, 466.97 10.14, 465 32 M465 32 C466.55 75.61, 466.6 115.25, 465 153 M465 32 C464.05 74.53, 463.24 116.37, 465 153 M465 153 C464.41 173.37, 454.7 186.2, 433 185 M465 153 C464.6 175.27, 456.16 184.99, 433 185 M433 185 C293.96 187.16, 156.58 185.46, 32 185 M433 185 C344.3 183.22, 255.91 182.95, 32 185 M32 185 C12.38 186.98, 0.18 176.13, 0 153 M32 185 C9.52 184.32, -0.53 172.7, 0 153 M0 153 C-0.95 118.45, 0.35 86.01, 0 32 M0 153 C0.05 123.13, -0.03 92.11, 0 32 M0 32 C-1.13 11.6, 10.28 -1.93, 32 0 M0 32 C2.08 9.66, 11.34 -0.14, 32 0" stroke="currentColor" stroke-width="2" fill="none"></path></g><g transform="translate(228.41333363850913 96.5) rotate(0 38.08666636149087 25)"><text x="38.086666361490884" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Phoenix</text><text x="38.086666361490884" y="42.62" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">PubSub</text></g><g stroke-linecap="round" transform="translate(75 59) rotate(0 63.5 64)"><path d="M31.75 0 C49.81 -0.08, 72.38 -1.33, 95.25 0 M31.75 0 C52.75 0.21, 72.34 -0.86, 95.25 0 M95.25 0 C116.44 1.56, 126.91 11.96, 127 31.75 M95.25 0 C117.22 -2.06, 126.77 9.26, 127 31.75 M127 31.75 C126.26 48.5, 128.1 64.61, 127 96.25 M127 31.75 C126.75 56.33, 125.97 81.16, 127 96.25 M127 96.25 C125.48 118.48, 115.31 126.6, 95.25 128 M127 96.25 C128.6 116.46, 118.7 126.55, 95.25 128 M95.25 128 C81.37 130, 68.23 128.79, 31.75 128 M95.25 128 C78.7 127.62, 63.85 127.91, 31.75 128 M31.75 128 C12.28 126.14, 1.16 118.41, 0 96.25 M31.75 128 C8.29 129.56, -0.97 118.66, 0 96.25 M0 96.25 C1.2 75.79, 0.37 58.61, 0 31.75 M0 96.25 C-0.19 78.96, 0.85 62.83, 0 31.75 M0 31.75 C1.34 10.56, 11.4 0.79, 31.75 0 M0 31.75 C0.63 10.19, 11.34 -1.19, 31.75 0" stroke="currentColor" stroke-width="2" fill="none"></path></g><g transform="translate(96.62000013987222 110.5) rotate(0 41.87999986012778 12.5)"><text x="41.879999860127775" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Registry</text></g><g stroke-linecap="round" transform="translate(333.5 59) rotate(0 63.5 64)"><path d="M31.75 0 C47.85 0.37, 69.02 -0.73, 95.25 0 M31.75 0 C57.21 0.42, 81.31 1.06, 95.25 0 M95.25 0 C116.3 -1.57, 125.73 8.73, 127 31.75 M95.25 0 C118.34 -0.73, 127.81 9.29, 127 31.75 M127 31.75 C126.74 50.52, 128.69 66.4, 127 96.25 M127 31.75 C127.03 48.34, 125.54 65.61, 127 96.25 M127 96.25 C126.81 118.05, 118.12 126.91, 95.25 128 M127 96.25 C126.16 116.94, 115.64 127.25, 95.25 128 M95.25 128 C80 127.68, 65.35 127.64, 31.75 128 M95.25 128 C77.25 127.78, 57.85 128.83, 31.75 128 M31.75 128 C9.11 126.56, 1.75 118.32, 0 96.25 M31.75 128 C8.94 129.25, -0.79 115.17, 0 96.25 M0 96.25 C0.82 75.09, -0.83 56.01, 0 31.75 M0 96.25 C-0.31 80.19, -0.01 63.09, 0 31.75 M0 31.75 C-0.07 9.35, 11.03 -0.05, 31.75 0 M0 31.75 C0.48 11.07, 10.97 1.89, 31.75 0" stroke="currentColor" stroke-width="2" fill="none"></path></g><g transform="translate(355.1200001398722 110.5) rotate(0 41.87999986012778 12.5)"><text x="41.879999860127775" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="currentColor" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Registry</text></g><g stroke-linecap="round" transform="translate(10 10) rotate(0 255.5 165.5)"><path d="M32 0 C176.9 -0.7, 322.62 0.68, 479 0 M32 0 C187.27 1.55, 342.79 1.51, 479 0 M479 0 C500.16 1.43, 512.22 8.79, 511 32 M479 0 C499.81 1.19, 512.08 11.29, 511 32 M511 32 C512.14 102.87, 510.45 174.15, 511 299 M511 32 C512.87 98.13, 513.21 163.94, 511 299 M511 299 C512.41 318.92, 498.62 331.2, 479 331 M511 299 C511.55 320.39, 499.89 331.84, 479 331 M479 331 C364.11 331.15, 249.62 331.24, 32 331 M479 331 C314.52 328.68, 149.52 328.53, 32 331 M32 331 C12.31 331.4, -1.19 322.24, 0 299 M32 331 C10.17 332.89, -0.29 318.91, 0 299 M0 299 C-2.61 203.72, -1.79 110.11, 0 32 M0 299 C1.77 192.46, 1.65 86.85, 0 32 M0 32 C-1.98 9.18, 9.81 1.95, 32 0 M0 32 C-0.42 11.88, 10.87 2.09, 32 0" stroke="#1971c2" stroke-width="2" fill="none"></path></g><g stroke-linecap="round" transform="translate(37 244) rotate(0 53.5 31)"><path d="M15.5 0 C36.16 1.14, 54.61 0.28, 91.5 0 M15.5 0 C30.14 -0.91, 46.69 -0.28, 91.5 0 M91.5 0 C103.58 -0.49, 105.58 4.99, 107 15.5 M91.5 0 C103.65 -2.19, 105.86 4.57, 107 15.5 M107 15.5 C107.5 22.81, 104.76 31.07, 107 46.5 M107 15.5 C106.99 24.95, 107.3 37.01, 107 46.5 M107 46.5 C107.78 55.7, 102.18 61.69, 91.5 62 M107 46.5 C106.41 55.78, 100.34 61.59, 91.5 62 M91.5 62 C72.23 64.56, 57.73 63.07, 15.5 62 M91.5 62 C73.49 62.69, 57.3 61.1, 15.5 62 M15.5 62 C6.1 62.85, -1.31 57.19, 0 46.5 M15.5 62 C7.01 62.88, 1.28 55.06, 0 46.5 M0 46.5 C-0.47 39.58, 1.96 33.64, 0 15.5 M0 46.5 C1.07 37.5, -0.17 28.55, 0 15.5 M0 15.5 C0.92 5.68, 5.15 -0.81, 15.5 0 M0 15.5 C1.73 5.49, 5.79 0.31, 15.5 0" stroke="#1971c2" stroke-width="2" fill="none"></path></g><g transform="translate(63.10999988615515 262.5) rotate(0 27.39000011384485 12.5)"><text x="27.39000011384487" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="#1971c2" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Client</text></g><g stroke-linecap="round" transform="translate(211.75 244) rotate(0 53.5 31)"><path d="M15.5 0 C31.34 0.64, 46.59 1.43, 91.5 0 M15.5 0 C42.57 -0.47, 70.49 0.02, 91.5 0 M91.5 0 C103.5 0.03, 106.83 3.56, 107 15.5 M91.5 0 C104.13 1.52, 106.32 4.02, 107 15.5 M107 15.5 C106.05 25.46, 108.46 34.55, 107 46.5 M107 15.5 C106.88 23.25, 106.23 29.1, 107 46.5 M107 46.5 C108.25 56.03, 100.57 61.01, 91.5 62 M107 46.5 C107.63 55.01, 102.96 61.15, 91.5 62 M91.5 62 C66.33 63.42, 39.31 62.05, 15.5 62 M91.5 62 C68.21 62.69, 44.39 63.07, 15.5 62 M15.5 62 C5.87 63.89, 1.7 55.2, 0 46.5 M15.5 62 C5.68 63.46, -1.16 55.01, 0 46.5 M0 46.5 C1.36 33.57, -1.77 23.43, 0 15.5 M0 46.5 C-1.04 38.03, -0.6 30.67, 0 15.5 M0 15.5 C0.24 3.42, 6.05 1.63, 15.5 0 M0 15.5 C-0.73 6.9, 5.37 -0.01, 15.5 0" stroke="#1971c2" stroke-width="2" fill="none"></path></g><g transform="translate(237.85999988615515 262.5) rotate(0 27.39000011384485 12.5)"><text x="27.39000011384487" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="#1971c2" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Client</text></g><g stroke-linecap="round" transform="translate(386.5 238) rotate(0 53.5 31)"><path d="M15.5 0 C44.41 1.35, 70.33 0.2, 91.5 0 M15.5 0 C45.97 -1.45, 76.48 -0.4, 91.5 0 M91.5 0 C100.63 0.85, 108.95 6.08, 107 15.5 M91.5 0 C100.48 0.95, 106.36 4.81, 107 15.5 M107 15.5 C107.68 24.53, 108.07 32.84, 107 46.5 M107 15.5 C106.9 24.48, 107.22 33.01, 107 46.5 M107 46.5 C108.12 56.7, 102.37 61.01, 91.5 62 M107 46.5 C108.52 57.44, 103.72 62.15, 91.5 62 M91.5 62 C69.87 61.43, 48.59 63.14, 15.5 62 M91.5 62 C71.39 61.53, 52.96 62.14, 15.5 62 M15.5 62 C3.21 60.95, -0.84 58.34, 0 46.5 M15.5 62 C3.52 63.43, 1.08 58.22, 0 46.5 M0 46.5 C-1.64 36.82, 0.52 26.36, 0 15.5 M0 46.5 C-0.48 38.07, -0.49 31.1, 0 15.5 M0 15.5 C-1.54 6.42, 3.37 0.57, 15.5 0 M0 15.5 C2.23 4.88, 6.42 2.09, 15.5 0" stroke="#1971c2" stroke-width="2" fill="none"></path></g><g transform="translate(412.60999988615515 256.5) rotate(0 27.39000011384485 12.5)"><text x="27.39000011384487" y="17.619999999999997" font-family="Excalifont, Segoe UI Emoji" font-size="20px" fill="#1971c2" text-anchor="middle" style="white-space: pre;" direction="ltr" dominant-baseline="alphabetic">Client</text></g>
</svg>

## UseCase #1: `Phoenix.Presence`

`Phoenix.Presence` is a fairly prominent feature of Phoenix. But keeping with
the theme of going from low-level to high-level abstraction `Phoenix.Tracker`
must be mentioned first.

`Phoenix.Tracker` enables cluster-wide tracking of processes, synchronizing
tracked processes and their metadata across nodes using `Phoenix.PubSub`.
`Phoenix.Tracker` employs conflict-free replication of state, avoiding the need
for global state or consensus protocols. Instead, each node maintains its own
eventually consistent copy of the tracked list.

Building upon Tracker's capabilities, `Phoenix.Presence` specializes this
functionality for tracking clients connected to Channels - or more specifically
the channel processes they're connected to. This powers the classic chat app
example, where you want to know the names of other users online in the chat
room.

`Phoenix.Presence` additionally integrates with `Phoenix.Channel`s for communcation
. It extends the state synchronization of the list of tracked presences
to external channel clients, so they can maintain their own eventually consistent
copy too.

## UseCase #2: `Phoenix.LiveView`

`Phoenix.LiveView` is a comparatively younger feature of Phoenix, which also
makes use of `Phoenix.Channel`s. It uses the communication between the elixir
node and an external browser over Channels to enable server driven interactivity
on websites work.

Given the primitive of `Phoenix.Channel`s already existing LiveView was able
to focus on what data it needs to share with the external client, already having
both websocket and long polling support provided as a means of being able to
talk to a liveview client.

LiveView is kinda interesting in that it doesn't use the Channel to broadcast
messages across the cluster using all the PubSub handling explained in this blog
post. It uses Channels just for the communication with a specific and single client.

That is however not to say that applications build using LiveView won't make use of
PubSub or Channels within LiveView.

Our exploration of Phoenix's real-time capabilities has taken us on a journey
through layers of powerful abstractions. Abstractions, which build a powerful,
scalable real-time communication system. Each layer builds upon the strengths
of those beneath it, providing developers with increasingly high-level tools
while maintaining the performance and distributed capabilities of the
underlying components.

By understanding these layers, developers can make informed decisions about
which abstractions to use for their specific needs, whether it's low-level
process management with Registry or building interactive, multi-user experiences
with Channels and Presence.
