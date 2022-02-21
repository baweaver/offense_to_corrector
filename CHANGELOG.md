## [Unreleased]

## [0.0.2] - 2022-02-21

- Refined underlying algorithms for computing nearest nodes
  - Range intersection dropped for string overlaps.
  - Closest node implemented on length of overlap and percentage of node source
    overlap to prevent matching higher-up parent nodes, but also avoid matching
    entire small child nodes that aren't as relevant.
- Fixed errors with unfindable atom nodes.
- Broke apart mono-file into related subdirectories, added basic specs

## [0.0.1] - 2022-02-20

- Initial release.
