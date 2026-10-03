# bufplugin-api-linter

A [Buf check plugin](https://buf.build/docs/cli/buf-plugins/overview/) that exposes every rule from
Google's [api-linter](https://github.com/googleapis/api-linter) as a Buf lint rule. This lets you
enforce [AIP](https://google.aip.dev) conformance with `buf lint`, alongside Buf's built-in rules,
without running a separate tool.

## Installation

```sh
go install gitlab.com/vaaripa/bufplugin-api-linter@latest
```

This installs the `bufplugin-api-linter` binary into `$(go env GOPATH)/bin`. Make sure it is on your `$PATH`.

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
