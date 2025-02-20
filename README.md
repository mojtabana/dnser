# dnser APT Repository

Welcome to the **dnser APT repository**! This repository provides prebuilt `.deb` packages of the `dnser` package for easy installation via APT, as well as the source code for building from source.

## Quick Start

To get started with the `dnser` package, follow these simple steps to add the APT repository and install the package.

### 1. Add the Repository to Your System

To add this APT repository to your system, run the following command:

```bash
echo "deb [trusted=yes] https://mojtabana.github.io/dnser stable main" | sudo tee /etc/apt/sources.list.d/dnser.list
```

### 2. Update the Package List

After adding the repository, run the following command to update your package list:

```bash
sudo apt update
```
