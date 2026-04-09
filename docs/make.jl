using Documenter
using SimpleBLE
using DocumenterTypst

makedocs(
    sitename = "SimpleBLE",
    authors = "Torfi Þorgrímsson",
    format = DocumenterTypst.Typst(),
    modules = [SimpleBLE],
    build = "build_typst",
    pages = [
        "Home" => "index.md",
        # "API" => "api.md",
    ]
)

makedocs(
    sitename = "SimpleBLE",
    format = Documenter.HTML(),
    modules = [SimpleBLE]
)


# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
deploydocs(
    repo = "https://github.com/AwesomeQuest/SimpleBLE.jl.git",
    deploy_repo = "https://github.com/AwesomeQuest/AwesomeQuest.github.io.git"

)