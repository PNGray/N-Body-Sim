include("vector.jl")
using Printf
mutable struct Body{T <: Vec}
    pos::T
    vel::T
    acc::T
    mass::Float64
    tag::Int
end

mutable struct Tree{T <: Vec}
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
    Tree(Vec2d(o.x + sp, o.y + sp), sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree(Vec2d(o.x, o.y + sp), sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree(o, sp, Vector{Tree{Vec2d}}(), nothing)
    , Tree(Vec2d(o.x + sp, o.y), sp, Vector{Tree{Vec2d}}(), nothing)
    ]
    children
end

function spawnChildren(o::Vec3d, s::Float64)::Vector{Tree{Vec3d}}
    sp = 0.5s
    children::Vector{Tree{Vec3d}} = [
    Tree(Vec3d(o.x + sp, o.y + sp, o.z + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x, o.y + sp, o.z + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x, o.y, o.z + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x + sp, o.y, o.z + sp), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x + sp, o.y + sp, o.z), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x, o.y + sp, o.z), sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(o, sp, Vector{Tree{Vec3d}}(), nothing)
    , Tree(Vec3d(o.x + sp, o.y, o.z), sp, Vector{Tree{Vec3d}}(), nothing)
    ]
    children
end



Base.:+(a::Body, b::Body) = Body(((a.mass * a.pos) + (b.mass * b.pos)) / (a.mass + b.mass), a.vel, a.acc, a.mass + b.mass, 0)
add(a::Body, b::Body) = begin
    mul(a.pos, a.mass)
    add(a.pos, b.mass * b.pos)
    a.mass += b.mass
    mul(a.pos, 1 / a.mass)
end

Base.show(io::IO, b::Body{Vec2d}) = @printf(io, "c %f %f %f", b.pos.x, b.pos.y, radius(b))
Base.show(io::IO, b::Body{Vec3d}) = @printf(io, "c3 %f %f %f %f", b.pos.x, b.pos.y, b.pos.z, 0.1)
showtrail(io::IO, b::Body{Vec3d}) = @printf(io, "ct3 %d %f %f %f %f", b.tag, b.pos.x, b.pos.y, b.pos.z, 0.1)


radius(b::Body{Vec2d})::Float64 = 0.25(b.mass^0.5)
radius(b::Body{Vec3d})::Float64 = 0.15(b.mass^(1/3))

function updatePos(a::Body{T}, dt::Float64) where {T}
    add(a.pos, dt * a.vel)
end

function updateVel(a::Body{T}, dt::Float64) where {T}
    mul(a.acc, dt)
    add(a.vel, a.acc)
    reset(a.acc)
end

function updateAcc(a::Body{T}, b::Body{T}, G::Float64) where {T}
    e = 0.5(radius(a) + radius(b))
    r = a.pos - b.pos
    rlensqr = lensqr(r)
    add(a.acc, -(G * b.mass / ((rlensqr + e^2)^1.5) * r))
end

function updateAccL(a::Body{T}, b::Body{T}, G::Float64) where {T}
    e = 0.5(radius(a) + radius(b))
    r = a.pos - b.pos
    rlensqr = lensqr(r)
    add(a.acc, -(G * b.mass / ((rlensqr + e^2)^1.5) * r))
end

function apply(a::Body{T}, tree::Tree{T}, theta::Float64, G::Float64, dt::Float64) where {T}
    if isEmpty(tree)
        return
    end
    if isLeaf(tree)
        if a.tag != tree.center.tag
            updateAcc(a, tree.center, G)
            println(tree.center.tag)
        end
    else
        if tree.size / dist(tree.center.pos, a.pos) < theta
            updateAcc(a, tree.center, G)
            println(tree.center.tag)
        else
            for i in tree.children
                apply(a, i, theta, G, dt)
            end
        end
    end
end
