module Linked_list

export Link, remove_link, push_link, is_empty, concat, showloop
mutable struct Link{T}
    next::Link{T}
    prev::Link{T}
    val::T
    Link{T}(next, prev, val) where T= new{T}(next, prev, val)
    Link{T}(val::T) where T= (x = new{T}(); x.next = x; x.prev = x; x.val = val; x)
    Link{T}() where T= (x = new{T}(); x.next = x; x.prev = x; x)
end

show_link(io::IO, l::Link) = begin
    if isdefined(l, :val)
        print(io, l.val, " ")
    else
        print(io, "#undef ")
    end
    return
end

Base.show(io::IO, l::Link) = begin
    show_link(io, l)
    current = l.next
    while current !== l
        show_link(io, current)
        current = current.next
    end
end


@inline function remove_link(l::Link)
    l.next.prev = l.prev
    l.prev.next = l.next
    return
end

function push_link(l1::Link, l2::Link)
    l3 = l1.next
    l1.next = l2
    l2.prev = l1
    l3.prev = l2
    l2.next = l3
    return
end

function is_empty(l::Link)::Bool
    l.next === l
end

function concat(l1::Link, l2::Link)
    if is_empty(l1) && is_empty(l2)
        return
    end
    l1.prev.next = l2.next
    l2.next.prev = l1.prev
    l1.prev = l2.prev
    l2.prev.next = l1
    l2.next = l2
    l2.prev = l2
    return
end

end


