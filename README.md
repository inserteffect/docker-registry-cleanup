# docker-registry-cleanup

Keep n versions of your builds in your private registry

## Usage

The following configuration options via environment variables are available:

| Variable          | Required | Purpose                                                                                     |
|-------------------|----------|---------------------------------------------------------------------------------------------|
| `REGISTRY_HOST`   | true     | The scheme and host of the private registry, e.g. `https://my-registry.example.com`         |
| `REPOSITORY_NAME` | true     | The name of the docker repository, e.g. `my-company/awesome-app`                            |
| `TAG_PREFIX`      | true     | Tag prefix for tags you want to remove, e.g. `build-version-` when tag is `build-version-1` |
| `USERNAME`        | false    | Name of the user who is allowed to push to the private registry                             |
| `PASSWORD`        | false    | Password of the user who is allowed to push to the private registry                         |
| `KEEP_VERSIONS`   | false    | The number of versions you want to keep, e.g. `5` (default: `10`)                           |
| `IGNORE_TAGS`     | false    | A list of tags you want to exclude from deletion, e.g. `latest, production`                 |

Currently the only supported authorization method is HTTP basic auth.
