module Vec_lib
export Vec, Vec2d, Vec3d, add, mul, dot, cross, len, lensqr, dist, midPoint, quadrant, num_dim, quad_relative, quad1, quad3_7

abstract type Vec end
#2d vector
mutable struct Vec2d <: Vec
    x::Float64
    y::Float64
    Vec2d(a, b, c) = new(a, b)
    Vec2d(a, b) = new(a, b)
    Vec2d(a) = new(a, a)
end

const ORIGIN2 = Vec2d(0.0, 0.0)
Base.:+(a::Vec2d, b::Vec2d) = Vec2d(a.x + b.x, a.y + b.y)
Base.:-(a::Vec2d, b::Vec2d) = Vec2d(a.x - b.x, a.y - b.y)
Base.:-(a::Vec2d) = Vec2d(-a.x, -a.y)
Base.:*(a::Float64, b::Vec2d) = Vec2d(a * b.x, a * b.y)
Base.:/(a::Vec2d, b::Float64) = (1 / b) * a
Base.:(==)(a::Vec2d, b::Vec2d) = a.x == b.x && a.y == b.y

#These modify the first vector without creating a new one, faster than +, *
add(a::Vec2d, b::Vec2d) = begin a.x += b.x; a.y += b.y; end
mul(a::Vec2d, b::Float64) = begin a.x *= b; a.y *= b; end
Base.reset(a::Vec2d) = begin a.x = 0.0; a.y = 0.0; end


dot(a::Vec2d, b::Vec2d)::Float64 = a.x * b.x + a.y * b.y #dot product
cross(a::Vec2d, b::Vec2d)::Float64 = a.x * b.y - a.y * b.x #cross product
lensqr(a::Vec2d) = a.x * a.x + a.y * a.y #len^2, for optimization
len(a::Vec2d) = sqrt(lensqr(a)) #lenght of vector
dist(a::Vec2d, b::Vec2d) = len(a - b) #distance between two points
midPoint(a::Vec2d, b::Vec2d) = (a + b) / 2

#return the quadrant of the point in space
function quadrant(a::Vec2d, b::Vec2d)::Int
    if a.x < b.x
        if a.y < b.y
            return 3
        else
            return 2
        end
    else
        if a.y < b.y
            return 4
        else
            return 1
        end
    end
end

function quad_relative(a::Vec2d, b::Vec2d)::Tuple{Int, Int}
    if a.x < b.x
        if a.y < b.y
            return (-1, -1)
        else
            return (-1, 1)
        end
    else
        if a.y < b.y
            return (1, -1)
        else
            return (1, 1)
        end
    end
end

function quad1(a::Vec2d, b::Vec2d)::Bool
    a.x > b.x && a.y > b.y
end

function quad3_7(a::Vec2d, b::Vec2d)::Bool
    a.x <= b.x && a.y <= b.y
end

#2d line
mutable struct Line2d
    root::Vec2d
    direction::Vec2d
end

fromPoints(a::Vec2d, b::Vec2d)::Line2d = Line2d(a, b - a)

function perBis(a::Vec2d, b::Vec2d)::Line2d
    root::Vec2d = midPoint(a, b)
    vector::Vec2d = a - b
    perpendicular::Vec2d = Vec2d(vector.y, -vector.x)
    return Line2d(root, perpendicular)
end

function yFromX(line::Line2d, x::Float64)::Float64
    dx::Float64 = x - line.root.x
    dy::Float64 = (dx / line.direction.x) * line.direction.y
    return line.root.y + dy
end

function xFromY(line::Line2d, y::Float64)::Float64
    dy::Float64 = y - line.root.y
    dx::Float64 = (dy / line.direction.y) * line.direction.x
    return line.root.x + dx
end

function cross(a::Line2d, b::Line2d)::Vec2d
    k::Float64 = 0
    droot::Vec2d = b.root - a.root
    if b.direction.y == 0
        k = droot.y / a.direction.y
    else
        ratio::Float64 = b.direction.x / b.direction.y
        xa::Float64 = a.direction.x - (a.direction.y * ratio)
        dax::Float64 = droot.x - (droot.y * ratio)
        k = dax / xa
    end
    return a.root + (k * a.direction)
end

Base.show(io::IO, a::Line2d) = begin
    b = a.root + a.direction
    return print(io, "l ", a.root.x, " ", a.root.y, " ", b.x, " ", b.y)
end




#3d vector, has the same methods as the 2d one

mutable struct Vec3d <: Vec
    x::Float64
    y::Float64
    z::Float64
    Vec3d(a) = new(a, a, a)
    Vec3d(a, b, c) = new(a, b, c)
end

const ORIGIN3 = Vec3d(0.0, 0.0, 0.0)
Base.:+(a::Vec3d, b::Vec3d) = Vec3d(a.x + b.x, a.y + b.y, a.z + b.z)
Base.:-(a::Vec3d, b::Vec3d) = Vec3d(a.x - b.x, a.y - b.y, a.z - b.z)
Base.:-(a::Vec3d) = Vec3d(-a.x, -a.y, -a.z)
Base.:*(a::Float64, b::Vec3d) = Vec3d(a * b.x, a * b.y, a * b.z)
Base.:/(a::Vec3d, b::Float64) = (1 / b) * a
Base.:(==)(a::Vec3d, b::Vec3d) = a.x == b.x && a.y == b.y && a.z == b.z


add(a::Vec3d, b::Vec3d) = begin a.x += b.x; a.y += b.y; a.z += b.z; end
add(a::Vec3d, b::Vec2d) = begin a.x += b.x; a.y += b.y; end
mul(a::Vec3d, b::Float64) = begin a.x *= b; a.y *= b; a.z *= b; end
Base.reset(a::Vec3d) = begin a.x = 0.0; a.y = 0.0; a.z = 0.0 end

dot(a::Vec3d, b::Vec3d)::Float64 = a.x * b.x + a.y * b.y + a.z * b.z
cross(a::Vec3d, b::Vec3d)::Vec3d = Vec3d(a.y * b.z - b.y * a.z, a.z * b.x - b.z * a.x, a.x * b.y - b.x * a.y)
lensqr(a::Vec3d) = a.x * a.x + a.y * a.y + a.z * a.z
len(a::Vec3d) = sqrt(lensqr(a))
dist(a::Vec3d, b::Vec3d) = len(a - b)
midPoint(a::Vec3d, b::Vec3d) = (a + b) / 2

function quadrant(a::Vec3d, b::Vec3d)::Int
    if a.z < b.z
        if a.x < b.x
            if a.y < b.y
                return 7
            else
                return 6
            end
        else
            if a.y < b.y
                return 8
            else
                return 5
            end
        end
    else
        if a.x < b.x
            if a.y < b.y
                return 3
            else
                return 2
            end
        else
            if a.y < b.y
                return 4
            else
                return 1
            end
        end
    end
end

function quad_relative(a::Vec3d, b::Vec3d)::Tuple{Int, Int, Int}
    if a.z < b.z
        if a.x < b.x
            if a.y < b.y
                return (-1, -1, -1)
            else
                return (-1, 1, -1)
            end
        else
            if a.y < b.y
                return (1, -1, -1)
            else
                return (1, 1, -1)
            end
        end
    else
        if a.x < b.x
            if a.y < b.y
                return (-1, -1, 1)
            else
                return (-1, 1, 1)
            end
        else
            if a.y < b.y
                return (1, -1, 1)
            else
                return (1, 1, 1)
            end
        end
    end
end

function quad1(a::Vec3d, b::Vec3d)::Bool
    a.x > b.x && a.y > b.y && a.z > b.z
end

function quad3_7(a::Vec3d, b::Vec3d)::Bool
    a.x <= b.x && a.y <= b.y && a.z <= b.z
end

num_dim(t::DataType)::Int = begin
    if t == Vec2d
        return 2
    elseif t == Vec3d
        return 3
    else
        return 0
    end
end

end
