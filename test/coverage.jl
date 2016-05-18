# Only run coverage from linux nightly build on travis.
get(ENV, "TRAVIS_OS_NAME", "")       == "linux"   || exit()
get(ENV, "TRAVIS_JULIA_VERSION", "") == "nightly" || exit()

Pkg.add("Coverage")
using Coverage

cd(Pkg.dir("PrivateModules")) do
    Codecov.submit(Codecov.process_folder())
end