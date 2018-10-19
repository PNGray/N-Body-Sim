module Bod_lib

export Body, showtrail, radius, updatePos, updateVel, updateAccGas
using Vec_lib
using Printf

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

const r0 = 0.15
const r02 = r0^2

function updateAccGas(a::Body{T}, b::Body{T}) where {T}
    r = a.pos - b.pos
    rlensqr = lensqr(r)
    runitsqr = rlensqr / r02
    f = 24(2 / runitsqr^7 - 1 / runitsqr^4) / r0
    add(a.acc, f * r)
end

end
