abstract type Vec end
#2d vector
Vec2d = Tuple{Float64, Float64}
Base.:+(a::Vec2d, b::Vec2d) = (a[1] + b[1], a[2] + b[2])
Base.:-(a::Vec2d, b::Vec2d) = (a[1] - b[1], a[2] - b[2])
Base.:-(a::Vec2d) = (-a[1], -a[2])
Base.:*(a::Float64, b::Vec2d) = (a * b[1], a * b[2])
Base.:/(a::Vec2d, b::Float64) = (1 / b) * a
Base.:(==)(a::Vec2d, b::Vec2d) = a[1] == b[1] && a[2] == b[2]



dot(a::Vec2d, b::Vec2d)::Float64 = a[1] * b[1] + a[2] * b[2] #dot product
cross(a::Vec2d, b::Vec2d)::Float64 = a[1] * b[2] - a[2] * b[1] #cross product
len(a::Vec2d) = sqrt(a[1]^2 + a[2]^2) #lenght of vector
lensqr(a::Vec2d) = a[1]^2 + a[2]^2 #len^2, for optimization
dis(a::Vec2d, b::Vec2d) = len(a - b) #distance between two points
midPoint(a::Vec2d, b::Vec2d) = (a + b) / 2

#return the quadrant of the point in space
function quadrant(a::Vec2d)::UInt
    if a[1] < 0
        if a[2] < 0
            return 3
        else
            return 2
        end
    else
        if a[2] < 0
            return 4
        else
            return 1
        end
    end
end




#2d line
Line2d = Tuple{Vec2d, Vec2d}

fromPoints(a::Vec2d, b::Vec2d)::Line2d = Line2d(a, b - a)

function perBis(a::Vec2d, b::Vec2d)::Line2d
    root::Vec2d = midPoint(a, b)
    vector::Vec2d = a - b
    perpendicular::Vec2d = Vec2d(vector[2], -vector[1])
    return (root, perpendicular)
end

function yFromX(line::Line2d, x::Float64)::Float64
    dx::Float64 = x - line[1][2]
    dy::Float64 = (dx / line[2][1]) * line[2][2]
    return line[1][2] + dy
end

function xFromY(line::Line2d, y::Float64)::Float64
    dy::Float64 = y - line[1][2]
    dx::Float64 = (dy / line[2][2]) * line[2][1]
    return line[1][2] + dx
end

function cross(a::Line2d, b::Line2d)::Vec2d
    k::Float64 = 0
    droot::Vec2d = b[1] - a[1]
    if b[2].y == 0
        k = droot[2] / a[2][2]
    else
        ratio::Float64 = b[2][1] / b[2][2]
        xa::Float64 = a[2][1] - (a[2][2] * ratio)
        dax::Float64 = droot[1] - (droot[2] * ratio)
        k = dax / xa
    end
    return a[1] + (k * a[2])
end

Base.show(io::IO, a::Line2d) = begin
    b = a[1] + a[2]
    return print(io, "l ", a[1].x, " ", a[1].y, " ", b[1], " ", b[2])
end




#3d vector, has the same methods as the 2d one

Vec3d = Tuple{Float64, Float64, Float64}
#Vec3d(a::Float64) = (a, a, a)
Base.:+(a::Vec3d, b::Vec3d) = (a[1] + b[1], a[2] + b[2], a[3] + b[3])
Base.:-(a::Vec3d, b::Vec3d) = (a[1] - b[1], a[2] - b[2], a[3] - b[3])
Base.:-(a::Vec3d) = Vec3d(-a[1], -a[2], -a[3])
Base.:*(a::Float64, b::Vec3d) = (a * b[1], a * b[2], a * b[3])
Base.:/(a::Vec3d, b::Float64) = (1 / b) * a
Base.:(==)(a::Vec3d, b::Vec3d) = a[1] == b[1] && a[2] == b[2] && a[3] == b[3]



dot(a::Vec3d, b::Vec3d)::Float64 = a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
cross(a::Vec3d, b::Vec3d)::Vec3d = (a[2] * b[3] - b[2] * a[3], a[3] * b[1] - b[3] * a[1], a[1] * b[2] - b[1] * a[2])
len(a::Vec3d) = sqrt(a[1]^2 + a[2]^2 + a[3]^2)
lensqr(a::Vec3d) = a[1]^2 + a[2]^2 + a[3]^2
dis(a::Vec3d, b::Vec3d) = len(a - b)
midPoint(a::Vec3d, b::Vec3d) = (a + b) / 2

Base.convert(::Type{Vec2d}, a::Vec3d) = (a[1], a[2])
function quadrant(a::Vec3d)::UInt
    quad = quadrant((a[1], a[2]))
    if a[3] >= 0
        return quad
    else
        return quad + 4
    end
end
