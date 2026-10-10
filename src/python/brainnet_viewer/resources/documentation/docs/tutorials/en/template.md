# Tutorial authoring template

[中文](../zh-CN/template.md)

Maintainer template, not an executable tutorial. Complete and validate every section when creating a concrete tutorial.

## 1. Identity and goal

Record the tutorial ID, paired titles, software build, documentation review date, intended reader and observable outcome.

## 2. Inputs and permission

List relative paths, source, author, license text, SHA-256, space/units/species and array sizes. Describe real inputs, project-created examples and internal benchmark data. Exclude participant-identifying information.

## 3. Prerequisites and parameters

State MATLAB/toolboxes/platform, measured estimated time, memory needs and parameter table. Ground defaults and scientific assumptions in code or specifications.

## 4. Numbered steps

Use stable step-01 anchors. Follow load → validate → configure → Apply (**commits and renders**) → interact/export. Use Render Scene only for an explicit redraw or after loading a preset. Each step needs an action, expected state and check; do not communicate parameters only through screenshots.

## 5. Expected image and replay

Include current-build English full-window captures, exported images, Scene/commands and numeric/image checks. Identify LOD, Safe Fit or rasterization. Concept art is not runtime evidence.

## 6. Errors and limitations

Include mismatched-input, parameter-interpretation and safe-failure examples. State what registration, significance and color-encoding assumptions the software cannot guarantee.

## 7. Delivery checks

Match steps/controls/parameters across languages; validate links and files; run commands in a clean session; visually review figures; verify permissions/citations; remove private paths; update the Changelog and documentation version.
