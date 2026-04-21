# builder

The `builder:` block controls how and where your Docker image is built
before `wheels deploy` pulls it onto the hosts. The current port
focuses on `docker build` + `docker push`; BuildKit bake, multi-arch
manifests, and remote builders map 1:1 to the Ruby Kamal options.

## Minimal — build locally, push to registry

    builder:
      context: .
      dockerfile: Dockerfile

## Multi-arch

    builder:
      arch:
        - amd64
        - arm64

Multi-arch images take longer to build locally on a single-arch laptop
because `docker buildx` emulates the foreign arch via QEMU. A remote
builder is usually faster.

## Build args

    builder:
      args:
        RUBY_VERSION: 3.3.0
        NODE_VERSION: 20

## Remote builder (arm64 Mac pushing amd64)

    builder:
      remote: ssh://deploy@builder.example.com
      arch: amd64

## What happens at deploy time

1. `builder create` — sets up a buildx builder (first deploy only).
2. `builder push` — `docker build` locally (or on the remote) then push.
3. `app run` on each host — pulls the tagged image and starts the
   new container.

## Commands

    wheels deploy build deliver   # build + push + pull on hosts
    wheels deploy build push      # just build + push
    wheels deploy build pull      # just pull on every host
    wheels deploy build create    # set up a buildx builder
    wheels deploy build remove    # tear down the buildx builder
    wheels deploy build details   # describe the configured builder
