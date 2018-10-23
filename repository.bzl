DEBUG=False

def _exec(ctx, args, strict=True):
    if DEBUG:
        print("EXEC", args)
    result = ctx.execute(args)
    if DEBUG:
        print(result.stdout)
        print(result.stderr)
    if strict and result.return_code != 0:
        fail("Failed", args)
    return result

def _impl(ctx):
    attr = ctx.attr
    repo = attr.repository if attr.repository else attr.name
    ctx.download(
        "https://api.github.com/repos/" + attr.owner + 
        "/" + repo + "/releases",
        "releases.json")

    if DEBUG:
        print(_exec(ctx, ["tree", "."]).stdout)

    # Get the response for the first artifact
    ctx.file("main.py", """
import json
import sys

def filter_assets(assets):
    for asset in assets:
        url = asset["browser_download_url"]
        if "darwin" in url:
             return asset
    return assets[0]

with open("releases.json", "r") as f:
    releases = json.loads(f.read())
    if not type(releases) is list:
        print("Invalid response")
        exit(1)
    info = releases[0]
    if type(info["assets"]) is list and len(info["assets"]) > 0:
        asset = filter_assets(info["assets"])
        sys.stdout.write("asset\\n")
        sys.stdout.write(asset["browser_download_url"])
    else:
        sys.stdout.write("zipball\\n")
        sys.stdout.write(info["zipball_url"])
""", True)
    info = _exec(ctx, ["python", "main.py"]).stdout.split("\n")
    release_kind = info[0]
    url = info[1]

    supported_exts = ["zip", "jar", "war", "tar", "tar.gz", "tgz",
                       "tar.xz","tar.bz2"]
    is_supported = False
    for ext in supported_exts:
        if url.endswith(ext):
            is_supported = True
            break

    if is_supported:
        ctx.download_and_extract(url, "out")
    else:
        # Download and unzip the archive
        ctx.download(
            url,
            "package.zip")

        _exec(ctx, [
            "unzip",
            "package.zip",
            "-d",
            "out"])

    if attr.build_file_contents:
        ctx.file("BUILD", attr.build_file_contents)
    elif _exec(ctx, ["ls", "BUILD"], strict=False).return_code != 0:
        # If there is no notion `BUILD` in the root, then codegen a BUILD file
        # with the name of the package.
        # FIXME: consider more robust methods here.
        repo_root = _exec(ctx, ["find", "out", "-perm", "+111", "-type", "f"]).stdout.split("\n")[0].split(" ")[0]
        build_file_contents = 'sh_binary(name="' + attr.name + '", srcs=["' + repo_root + '"], deps=[":lib"])\nsh_library(name="lib", srcs=glob(["out/**/*"]))' 
        ctx.file("BUILD", build_file_contents)

# Import a github repository on the latest release.
# github_repository queries the github API and loads releases from there
#
# Is this secure?
# Currently, it relies on https and simply loads the results of github.com.
github_repository = repository_rule(
    implementation=_impl,
    attrs={
        "owner": attr.string(mandatory=True),
        "repository": attr.string(mandatory=False), # defaults to `name`
        "build_file_contents": attr.string(mandatory=False),
    }
)

