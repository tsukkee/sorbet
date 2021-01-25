load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("//third_party:sorbet_version.bzl", "SORBET_SHA256", "SORBET_VERSION")

def _github_public_urls(path):
    return [
        "https://github.com/{}".format(path),
        "https://artifactory-content.stripe.build/artifactory/github-archives/{}".format(path),
    ]

def _rubygems_urls(gem):
    return [
        "https://rubygems.org/downloads/{}".format(gem),
        "https://artifactory-content.stripe.build/artifactory/gems/gems/{}".format(gem),
    ]

def _zlib_urls(path):
    return [
        "https://zlib.net/{}".format(path),
        "https://artifactory-content.stripe.build/artifactory/zlib-cache/{}".format(path),
    ]

def _ruby_urls(path):
    return [
        "https://cache.ruby-lang.org/pub/ruby/{}".format(path),
        "https://artifactory-content.stripe.build/artifactory/ruby-lang-cache/pub/ruby/{}".format(path),
    ]

# We define our externals here instead of directly in WORKSPACE
def sorbet_llvm_externals():
    # WARNING: if you're using a local version of sorbet you won't get patches
    # applied to test_corpus_runner that run sorbet_llvm during testing.
    use_local = False
    if not use_local:
        http_archive(
            name = "com_stripe_ruby_typer",
            urls = _github_public_urls("sorbet/sorbet/archive/{}.zip".format(SORBET_VERSION)),
            sha256 = SORBET_SHA256,
            strip_prefix = "sorbet-{}".format(SORBET_VERSION),
            patch_args = ["-p1"],
            patches = ["@com_stripe_sorbet_llvm//third_party:sorbet_test_corpus_runner.patch"],
        )
    else:
        native.local_repository(
            name = "com_stripe_ruby_typer",
            path = "../sorbet/",
        )

    http_archive(
        name = "llvm",

        # llvm 9.0.1
        urls = _github_public_urls("llvm/llvm-project/archive/c1a0a213378a458fbea1a5c77b315c7dce08fd05.tar.gz"),
        build_file = "@com_stripe_sorbet_llvm//third_party/llvm:llvm.autogenerated.BUILD",
        sha256 = "81a1a2ef99a780759b03dbcc926f11ce75acbdf227c1c66cce6f2057b58a962b",
        strip_prefix = "llvm-project-c1a0a213378a458fbea1a5c77b315c7dce08fd05/llvm",
    )

    http_archive(
        name = "zlib_archive",
        urls = _zlib_urls("zlib-1.2.11.tar.gz"),
        build_file = "@com_stripe_sorbet_llvm//third_party:zlib.BUILD",
        sha256 = "c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1",
        strip_prefix = "zlib-1.2.11",
    )

    http_file(
        name = "bundler_stripe",
        urls = _rubygems_urls("bundler-1.17.3.gem"),
        sha256 = "bc4bf75b548b27451aa9f443b18c46a739dd22ad79f7a5f90b485376a67dc352",
    )

    http_file(
        name = "rubygems_update_stripe",
        urls = _rubygems_urls("rubygems-update-3.1.2.gem"),
        sha256 = "7bfe4e5e274191e56da8d127c79df10d9120feb8650e4bad29238f4b2773a661",
    )

    ruby_unpatched_build = "@com_stripe_sorbet_llvm//third_party/ruby:ruby_unpatched.BUILD"
    ruby_patched_build = "@com_stripe_sorbet_llvm//third_party/ruby:ruby_patched.BUILD"

    http_archive(
        name = "sorbet_ruby",
        urls = _ruby_urls("2.6/ruby-2.6.5.tar.gz"),
        sha256 = "66976b716ecc1fd34f9b7c3c2b07bbd37631815377a2e3e85a5b194cfdcbed7d",
        strip_prefix = "ruby-2.6.5",
        build_file = ruby_unpatched_build,
    )

    for apply_patch in [True, False]:
        urls = _ruby_urls("2.7/ruby-2.7.2.tar.gz")
        sha256 = "6e5706d0d4ee4e1e2f883db9d768586b4d06567debea353c796ec45e8321c3d4"
        strip_prefix = "ruby-2.7.2"

        if apply_patch:
            http_archive(
                name = "sorbet_ruby_2_7",
                urls = urls,
                sha256 = sha256,
                strip_prefix = strip_prefix,
                build_file = ruby_patched_build,
                # If you're trying to use `git diff` to generate this patch, pass the `--no-prefix` flag
                # (Removes the `a/` and `b/` prefixes that `patch` doesn't understand.)
                patches = [
                    "@com_stripe_sorbet_llvm//third_party/ruby:gc-remove-write-barrier.patch",
                ],
                patch_tool = "patch",
            )
        else:
            http_archive(
                name = "sorbet_ruby_2_7_unpatched",
                urls = urls,
                sha256 = sha256,
                strip_prefix = strip_prefix,
                build_file = ruby_unpatched_build,
            )
