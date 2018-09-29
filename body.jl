include("vector.jl")
using Printf
mutable struct Body{T}
    pos::T
    vel::T
    acc::T
    mass::Float64
    tag::Int
end

mutable struct Tree{T}
    origin::T
    size::Float64
    children::Vector{Tree{T}}
    center::Union{Body{T}, Nothing}
end

isLeaf(tree::Tree)::Bool = length(tree.children) == 0
isEmpty(tree::Tree)::Bool = tree.center == nothing

function push(tree::Tree{T}, a::Body{T}) where {T}
    if isLeaf(tree)
        if isEmpty(tree)
            tree.center = a
        else
            b = tree.center
            tree.center = a + b
            tree.children::Vector{Tree{T}} = spawnChildren(tree.origin, tree.size)
            middle::T = tree.children[1].origin
            push(tree.children[quadrant(a.pos - middle)], a)
            push(tree.children[quadrant(b.pos - middle)], b)
        end
    else
        middle = tree.children[1].origin
        add(tree.center, a)
        push(tree.children[quadrant(a.pos - middle)], a)
    end
end

function spawnChildren(o::Vec2d, s::Float64)::Vector{Tree{Vec2d}}
    sp = 0.5s
    children::Vector{Tree{Vec2d}} = [
    Tree((o[1] + sp, o[2] + sp), sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree((o[1], o[2] + sp), sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree(o, sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree((o[1] + sp, o[2]), sp, Vector{Tree{Vec2d}}(), nothing)
    ]
    children
end

function spawnChildren(o::Vec3d, s::Float64)::Vector{Tree{Vec3d}}
    sp = 0.5s
    children::Vector{Tree{Vec3d}} = [
    Tree((o[1] + sp, o[2] + sp, o[3] + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree((o[1], o[2] + sp, o[3] + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree((o[1], o[2], o[3] + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree((o[1] + sp, o[2], o[3] + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree((o[1] + sp, o[2] + sp, o[3]), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree((o[1], o[2] + sp, o[3]), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(o, sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree((o[1] + sp, o[2], o[3]), sp, Vector{Tree{Vec3d}}(), nothing)
    ]
    children
end



Base.:+(a::Body, b::Body) = Body(((a.mass * a.pos) + (b.mass * b.pos)) / (a.mass + b.mass), a.vel, a.acc, a.mass + b.mass, 0)
add(a::Body, b::Body) = begin
    a.pos *= a.mass
    a.pos += b.mass * b.pos
    a.mass += b.mass
    a.pos /= a.mass
end

Base.show(io::IO, b::Body{Vec2d}) = @printf(io, "c %f %f %f", b.pos[1], b.pos[2], radius(b))
Base.show(io::IO, b::Body{Vec3d}) = @printf(io, "c3 %f %f %f %f", b.pos[1], b.pos[2], b.pos[3], radius(b))


radius(b::Body{Vec2d})::Float64 = 0.25(b.mass^0.5)
radius(b::Body{Vec3d})::Float64 = 0.15(b.mass^(1/3))

function updatePos(a::Body{T}, dt::Float64) where {T}
    a.pos += dt * a.vel
end

function updateVel(a::Body{T}, dt::Float64) where {T}
    a.vel += dt * a.acc
    a.acc = (0.0, 0.0, 0.0)
end

function updateAcc(a::Body{T}, b::Body{T}, G::Float64) where {T}
    e = 0.5(radius(a) + radius(b))
    r = a.pos - b.pos
    rlensqr = lensqr(r)
    a.acc += -(G * b.mass / ((rlensqr + e^2)^1.5)) * r
end

function apply(a::Body{T}, tree::Tree{T}, theta::Float64, G::Float64, dt::Float64) where {T}
    if isEmpty(tree)
        return
    end
    if isLeaf(tree)
        if a.tag != tree.center.tag
            updateAcc(a, tree.center, G)
        end
    else
        if tree.size / dis(tree.center.pos, a.pos) < theta
            updateAcc(a, tree.center, G)
        else
            for i in tree.children
                apply(a, i, theta, G, dt)
            end
        end
    end
end
