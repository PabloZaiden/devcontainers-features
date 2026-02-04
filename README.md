# Dev Container Features

This repository contains a collection of Dev Container Features.

## Features

### Bun

Installs [Bun](https://bun.sh), an all-in-one JavaScript runtime & toolkit designed for speed.

#### Usage

Add the following to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/pablozaiden/devcontainers-features/bun:1": {}
    }
}
```

#### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Bun version to install. Use `latest` for the most recent stable version, `canary` for the latest development build, or specify a version number (e.g., `1.1.0`). |

#### Example with specific version

```json
{
    "features": {
        "ghcr.io/pablozaiden/devcontainers-features/bun:1": {
            "version": "1.1.0"
        }
    }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see the [LICENSE](LICENSE) file for details.
