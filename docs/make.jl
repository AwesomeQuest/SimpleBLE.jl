using Documenter
using SimpleBLE
using DocumenterTypst

# makedocs(
#     sitename = "SimpleBLE",
#     authors = "Torfi Þorgrímsson",
#     format = DocumenterTypst.Typst(),
#     modules = [SimpleBLE],
#     build = "build_typst",
#     pages = [
#         "Home" => "index.md",
#         # "API" => "api.md",
#     ]
# )

makedocs(
    sitename = "SimpleBLE",
    format = Documenter.HTML(),
    build = "SimpleBLE.jl",
    modules = [SimpleBLE]
)

