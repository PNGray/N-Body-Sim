module Linked_list

export Link, remove_link, push_link, is_empty
mutable struct Link{T}
    next::Link{T}
    prev::Link{T}
    val::T
    Link{T}(next, prev, val) where T= new{T}(next, prev, val)
    Link{T}() where T= (x = new{T}(); x.next = x; x.prev = x)
end

function remove_link(l::Link)
    l.next.prev = l.prev
    l.prev.next = l.prev.next
end

function push_link(l1::Link, l2::Link)
    l3 = l1.next
    l1.next = l2
    l2.prev = l1
    l3.prev = l2
    l2.next = l3
end

function is_empty(l::Link)
    !isdefined(l.next, :val)
end

end


