# bufplugin-api-linter

A [Buf check plugin](https://buf.build/docs/cli/buf-plugins/overview/) that exposes every rule from
Google's [api-linter](https://github.com/googleapis/api-linter) as a Buf lint rule. This lets you
enforce [AIP](https://google.aip.dev) conformance with `buf lint`, alongside Buf's built-in rules,
without running a separate tool.

## Installation

### Prebuilt binary

Download the archive for your platform from the
[releases page](https://github.com/vaaripa/bufplugin-api-linter/releases). Binaries are published for
`darwin/arm64`, `linux/amd64` and `linux/arm64`.

```sh
VERSION=v0.1.0   # pick a release tag
OS=linux         # linux or darwin
ARCH=amd64       # amd64 or arm64
curl -sSL "https://github.com/vaaripa/bufplugin-api-linter/releases/download/${VERSION}/bufplugin-api-linter_${VERSION}_${OS}_${ARCH}.tar.gz" \
  | tar -xz -C /usr/local/bin bufplugin-api-linter
```

### From source

```sh
go install github.com/vaaripa/bufplugin-api-linter@latest
```

This installs the binary into `$(go env GOPATH)/bin`.

Either way, make sure `bufplugin-api-linter` is on your `$PATH` so `buf` can find it.

## Usage

Register the plugin in `buf.yaml` (v2) and enable the `AIP_ALL` category:

```yaml
version: v2
lint:
  use:
    - STANDARD
    - AIP_ALL
plugins:
  - plugin: bufplugin-api-linter
```

Then run:

```sh
buf lint
```

To list all rules provided by the plugin:

```sh
buf config ls-lint-rules
```

## Rule naming

Each api-linter rule is mapped to a Buf rule ID by prefixing `AIP_`, upper-casing, and replacing
`::` and `-` with `_`:

| api-linter rule            | Buf rule ID                  |
| -------------------------- | ---------------------------- |
| `core::0192::has-comments` | `AIP_CORE_0192_HAS_COMMENTS` |

All rules are enabled by default and belong to the `AIP_ALL` category. Disable individual rules
with `lint.except`, or for specific paths with `lint.ignore_only`:

```yaml
lint:
  use:
    - AIP_ALL
  except:
    - AIP_CORE_0192_HAS_COMMENTS
  ignore_only:
    AIP_CORE_0131_HTTP_BODY:
      - proto/legacy
```

## Notes

- Only files in your module are linted; imported files are skipped.
- Rules run with api-linter's default configuration.

## Credits

Originally based on [googleapis/api-linter#1463](https://github.com/googleapis/api-linter/pull/1463). This version targets api-linter v2 and runs rules through api-linter's linter rather than calling them directly, so disable comments are respected.
