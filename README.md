<div align="center">
  <h1>Synapse</h1>
  <p>A semantic application launcher and desktop search application for GNOME.</p>
  <a href="https://github.com/paysonwallach/synapse/releases/latest">
    <img alt="Version 0.4.7" src="https://img.shields.io/badge/version-0.4.7-red.svg?cacheSeconds=2592000&style=flat-square" />
  </a>
  <a href="https://github.com/paysonwallach/synapse/blob/master/COPYING.md" target="\_blank">
    <img alt="Licensed under the GNU Lesser General Public License v2.1" src="https://img.shields.io/badge/license-LGPL%20v2.1-blue.svg?style=flat-square" />
  <a href=https://buymeacoffee.com/paysonwallach>
    <img src=https://img.shields.io/badge/donate-Buy%20me%20a%20coffe-yellow?style=flat-square>
  </a>
  <br>
  <br>
</div>

## Background

[Synapse](https://github.com/paysonwallach/synapse) is a semantic application launcher and desktop search utility for GNOME, built on its activity-logging service, [Zeitgeist](https://launchpad.net/zeitgeist-project), which helps ensure provided results are always relevant. It features a powerful, dynamic, plugin-based architecture which allows for easy integration with any number of applications and services.

## Installation

Clone this repository or download the [latest release](https://github.com/paysonwallach/synapse/releases/latest).

```shell
git clone https://github.com/paysonwallach/synapse
```

Configure the build directory at the root of the project.

```shell
meson --prefix=/usr build
```

Install with `ninja`.

```shell
ninja -C build install
```

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change. By participating in this project, you agree to abide by the terms of the [Code of Conduct](https://github.com/paysonwallach/synapse/blob/master/CODE_OF_CONDUCT.md).

## License

[Synapse](https://github.com/paysonwallach/synapse) is licensed under the [GNU Lesser General Public License v2.1](https://github.com/paysonwallach/synapse/blob/master/COPYING.md).
