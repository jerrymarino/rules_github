Bazel build rules for github repositories.

## github_repository

`github_repository` is a workspace rule that makes it easy to install Github releases into Bazel.

_It simplifies running software from Github by using Github releases and Bazel as a way to install and update the packages locally._

### Usage

Import `github_repostiory` to a Bazel workspace

```
git_repository(
    name="rules_github",
    url="https://github.com/jerrymarino/rules_github.git",
    branch="master"
)

load("@rules_github//:repository.bzl", "github_repository")
```

Next, setup packages

```
# Add the binary `rg` from BurntSushi/ripgrep
github_repository(
    name = "rg",
    owner = "BurntSushi",
    repository = "ripgrep",
)
```

"build" the binary with `bazel`

```
bazel build @rg//:rg
```

After download, the binary is available in `bazel-bin/external/rg`.

_note: it's possible to use `bazel run`, which has performance overhead compared to running the program directly._

### Loading Bazel built Github programs onto the path

After "building" the `github_repository`'s, they are available in the directory, `bazel-bin`.

```
# Add `bazel-bin` to the path
export PATH="$PATH:$(find bazel-bin/external -d 1 -type d | tr '\n' ':')"
```

## Caveats

### Transitive build dependencies

For many releases, transitive dependencies may be compiled into the release
binary. For building packages from source, Bazel needs transitive dependencies
specified. This topic is nuanced and out of scope of `rules_github`. 

## FAQ

### Why use `rules_github` instead of `git_repository` and git archives?

Git archives are useful for storing source code and are widely used for this
purpose on github. In many scenarios, source builds aren't ideal as it adds requirements to the build environment and many take significant time.

### Does `git_repository` work here?

Many applications on [www.github.com]() are distributed in a pre-built binary form - `git_repository` won't work for this situation. `github_repository` works because it is integrated into the github API.

### When does it update the packages

The Bazel [`repository_rule`](https://blog.bazel.build/2017/02/22/repository-invalidation.html) documentation contains a detailed explanation of this topic.

