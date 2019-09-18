module Body_lib

using Vec_lib
using Printf
export Body, showtrail, radius, updatePos, updateVel, generate2d, generate3d

mutable struct Body{T <: Vec}
    pos::T
    vel::T
    acc::T
    mass::Float64
    tag::Int
end


Base.:+(a::Body, b::Body) = Body(((a.mass * a.pos) + (b.mass * b.pos)) / (a.mass + b.mass), a.vel, a.acc, a.mass + b.mass, 0)
Vec_lib.add(a::Body, b::Body) = begin
    mul(a.pos, a.mass)
    add(a.pos, b.mass * b.pos)
    a.mass += b.mass
    mul(a.pos, 1 / a.mass)
end

Base.show(io::IO, b::Body{Vec2d}) = @printf(io, "c %f %f %f", b.pos.x, b.pos.y, radius(b))
Base.show(io::IO, b::Body{Vec3d}) = @printf(io, "c3 %f %f %f %f", b.pos.x, b.pos.y, b.pos.z, radius(b))
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

function generate2d(infile::IO)
    str = read(infile, String)
    list = map(x->split(x, " "), split(str, "\n"))
    T = Vec2d
    bodies::Vector{Body{T}} = []
    for i in 1:length(list)
        if length(list[i]) < 5 continue end
        elems = map(x->parse(Float64, x), list[i])
        pos = Vec2d(elems[1], elems[2])
        vel = Vec2d(elems[3], elems[4])
        mass = elems[5]
        push!(bodies, Body(pos, vel, Vec2d(0.0, 0.0), mass, i))
    end
    bodies
end

function generate3d(infile::IO)
    str = read(infile, String)
    list = map(x->split(x, " "), split(str, "\n"))
    T = Vec3d
    bodies::Vector{Body{T}} = []
    for i in 1:length(list)
        if length(list[i]) < 7 continue end
        elems = map(x->parse(Float64, x), list[i])
        pos = Vec3d(elems[1], elems[2], elems[3])
        vel = Vec3d(elems[4], elems[5], elems[6])
        mass = elems[7]
        push!(bodies, Body(pos, vel, Vec3d(0.0, 0.0, 0.0), mass, 2))
    end
    bodies
end

end
