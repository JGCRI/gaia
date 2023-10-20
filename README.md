<!-- badges: start -->
[![build](https://github.com/JGCRI/rtemplate/workflows/build/badge.svg)](https://github.com/JGCRI/rtemplate/workflows/build/badge.svg?branch=main)
[![test_coverage](https://github.com/JGCRI/rtemplate/actions/workflows/test_coverage.yml/badge.svg?branch=main)](https://github.com/JGCRI/rtemplate/actions/workflows/test_coverage.yml)
[![codecov](https://codecov.io/gh/JGCRI/rtemplate/branch/main/graph/badge.svg?token=XQ913U4IYM)](https://codecov.io/gh/JGCRI/rtemplate)
[![docs](https://github.com/JGCRI/rtemplate/actions/workflows/docs.yaml/badge.svg?branch=main)](https://github.com/JGCRI/rtemplate/actions/workflows/docs.yaml)
<!-- badges: end -->


# Introduction

`rtemplate` is a template for creating a basic R package with Continuous Integration (CI) via GitHub actions in the following steps:

<br>
<br>

<a href="https://raw.githubusercontent.com/JGCRI/rtemplate/main/vignettes/vignetteFigs/rtemplate_build_your_own_package.png?raw=true" onclick="window.open(this.href); return false;"><img src="https://raw.githubusercontent.com/JGCRI/rtemplate/main/vignettes/vignetteFigs/rtemplate_build_your_own_package.png?raw=true" max-width="80%"/></a>

<br>
<br>

The folder structure is as shown below:

<br>
<br>

<a href="https://raw.githubusercontent.com/JGCRI/rtemplate/main/vignettes/vignetteFigs/rtemplate_package_structure.png?raw=true" onclick="window.open(this.href); return false;"><img src="https://raw.githubusercontent.com/JGCRI/rtemplate/main/vignettes/vignetteFigs/rtemplate_package_structure.png?raw=true" max-width="80%"/></a>

<br>
<br>

# 1 Clone or "Use this template"

Navigate directly to https://github.com/JGCRI/rtemplate, click the shiny green button that says `Use this template` and be on your way.

You can also clone the template to view the files locally and then copy into your own repo as needed:

```bash
git clone https://github.com/JGCRI/rtemplate.git
```

# 2 Update Package Information

Update your information (package name and other details) in the following files:

- README.md
- DESCRIPTION
- LICENSE

# 3 Update Package Modules

This is where you write the main code for your model. We have include some key modules and tests. You should write tests for all your modules as you develop them.

- R\rtemplate.R (This defines your package and provides the help/documentation for the package.)
- R\example_function.R (This is an example function with documentation. You can copy this to create other functions.)

# 4 Update Tests

We provide a sample test file that should be updated as you add in new modules and classes. These tests are linked to the GitHub Action so that every time you push any changes your tests are executed. The GitHub action also links to `codecov` so that you know how much of your code is covered by the tests you have written. You should aim to keep this percentage to above 70%.

- tests\testthat.R (Update package name here)
- tests\testthat\test-rtemplate.R (Write unit and integration tests for each of your functions here.)


# 5 Update Package Documentation

Update each of the following files to generate clean, clear documentation. When you push your changes to github the github actions described in the next section will automatically build the documentation page online for you. An example for this repo is available at: https://jgcri.github.io/rtemplate/. 

- _pkgdown.yml
- CITATION.md
- CONTRIBUTE.md
- DISCLAIMER
- LICENSE
- NEWS.md
- SUPPORT.md

Once your GitHub action for docs is complete (see section 6 GitHub Actions) you need the following steps to get your documentation page live online:

<br>
<br>

<a href="https://raw.githubusercontent.com/JGCRI/rtemplate/main/vignettes/vignetteFigs/rtemplate_activate_docs.png?raw=true" onclick="window.open(this.href); return false;"><img src="https://raw.githubusercontent.com/JGCRI/rtemplate/main/vignettes/vignetteFigs/rtemplate_activate_docs.png?raw=true" max-width="80%"/></a>

<br>
<br>

# 6 Github Actions

The final piece is to check your GitHub actions for continuous integration. These actions have been written so they are trigger everytime you push to main or execute a pull request to main. There are four GitHub actions included with this package as follows: 

- .github\workflows\build.yml (Tests if package builds on windows, macos, ubuntu)
- .github\workflows\docs.yml (Automatically builds your documentation from the vignette folder and hosts on GitHub pages)
- .github\workflows\test.yml (Runs your tests and check what percentage is covered on codecov. You will need to connect your repository to codecoverage for this to work as shown below.)

<br>
<br>

<a href="https://raw.githubusercontent.com/JGCRI/rtemplate/main/vignettes/vignetteFigs/rtemplate_codecov.png?raw=true" onclick="window.open(this.href); return false;"><img src="https://raw.githubusercontent.com/JGCRI/rtemplate/main/vignettes/vignetteFigs/rtemplate_codecov.png?raw=true" max-width="80%"/></a>

<br>
<br>

The final step is to add your badges to your repository as follows. Simply replace "rtemplate" with your own repo name in the following three badges and then paste these at the top of the README.md file and push:

```
[![build](https://github.com/JGCRI/rtemplate/actions/workflows/build.yml/badge.svg)](https://github.com/JGCRI/rtemplate/actions/workflows/build.yml)
[![docs](https://github.com/JGCRI/rtemplate/actions/workflows/docs.yml/badge.svg)](https://github.com/JGCRI/rtemplate/actions/workflows/docs.yml)
[![tests](https://github.com/JGCRI/rtemplate/actions/workflows/test.yml/badge.svg)](https://github.com/JGCRI/rtemplate/actions/workflows/test.yml)
```
For the codecoverage badge use the Markdown badge you copied from codecov as shown in the final step above.








  
