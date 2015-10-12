__precompile__()

"""
    PrivateModules

Provides an `@private` macro for hiding unexported symbols.
"""
module PrivateModules

using Base.Meta, Compat

export @private

"""
    @private module ... end

Make unexported symbols in a module private.

**Example**

```julia
using PrivateModules

@private module M

export f

f(x) = g(x, 2x)

g(x, y) = x + y

end

using .M

f(1)      # works
M.g(1, 2) # fails
```
"""
macro private(x) private(x) end

function private(x)
    isexpr(x, :module) || error("not a valid module expression:\n\n$x")

    # Rename module.
    outer = x.args[2]
    inner = symbol(outer, "#private")
    x.args[2] = inner

    # Change `eval` module reference to new inner module.
    x.args[end].args[1].args[end].args[end].args[2] = inner

    # Build outer module.
    out = :(module $outer end)
    push!(out.args[end].args,
        x,                                   # Original module.
        :($(exports)($outer, $inner)),       # Exported symbols.
        macroexpand(:(Base.@__doc__ $outer)) # Documentation.
    )

    Expr(:toplevel, esc(out))
end

"""
    exports(outer, inner)

Import all exported symbols from `inner` module into `outer` one and then re-export them.
"""
function exports(outer, inner)
    symbols = names(inner)
    imports = [Expr(:import, :., module_name(inner), s) for s in symbols]
    eval(outer, Expr(:toplevel, imports...))
    eval(outer, Expr(:toplevel, Expr(:export, symbols...)))
end

end # module