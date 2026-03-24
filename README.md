# Orchestrion

Orchestrion is a small UI for managing multiple `systemd` services from one place.

It was motivated by a practical workflow problem: repeatedly opening many terminals, manually starting around 30 long-running processes, and watching their output across tabs and panes. That works, but it is manual, fragile, and difficult to scan at a glance.

Orchestrion should provide a simpler way to do the same job using `systemd` under the hood.

## What it should do

- Read a config file that defines the managed entries.
- Create or update the corresponding `systemd` services from that config.
- Start, stop, and monitor those services.
- Show the state of each service clearly.
- Use colour to indicate service state.
- Show log output for each service.
- Allow opening a larger log view so output can be read in a way that feels similar to watching it in a terminal.
- Make it easy to start the full working set without manually launching all 30 services one by one.
- Support grouping the services in two useful ways: by system, and by service type.
- Provide an at-a-glance overview of all systems so it is easy to quickly scan what is running, stopped, or failed.

## Context

The initial use case is a group of ROS 2 Python nodes that are usually started with `ros2 run ...`, but Orchestrion should not be tightly coupled to ROS. The useful abstraction is a managed service, not a ROS-specific tool.

The current manual workflow uses Terminator with multiple tabs and panes to keep many processes visible at once. Orchestrion exists to replace that workflow with something more reliable and easier to control, while still preserving the ability to quickly see what is running, what has stopped, and what has failed.

The services also have a natural two-dimensional structure: there are multiple systems, and each system has a small set of associated service types. Orchestrion should reflect that by making it easy to view the same managed set either by system or by type, without baking in any one specific naming scheme.

## Config

Orchestrion should use a config file as the source of truth for the services it manages.

The config should be simple. It should contain the information needed to define the managed entries and start them consistently. The exact schema is left open for implementation.

## Alternatives

Cockpit already provides a web UI for inspecting and controlling `systemd` services and viewing logs. That makes it a useful baseline and a valid alternative.

The reason Orchestrion may still be useful is that it can be tailored to this specific workflow: many related services, clear status at a glance, and a service-oriented view that is closer to the existing terminal-based setup.

## Scope

This project is about the UI and workflow around `systemd` services.

It is not trying to replace `systemd`, build a custom process supervisor, or invent a new logging system.
