struct Frustum
    box_clip_space::BBox
end

function Frustum()
    center = SVector{3, Float32}(0f0, 0f0, 0.5f0)
    radius = SVector{3, Float32}(1f0, 1f0, 0.5f0)
    box_clip_space = BBox(center - radius, center + radius)
    Frustum(box_clip_space)
end

"""
    draw(f::Frustum, fL, P, L)

# Arguments:

- `f::Frustum`: Frustum to render.
- `fL`: Frustum camera's look at matrix.
- `P`: User controlled camera's perspective matrix.
- `L`: User controlled camera's look at matrix.
- `color`: Color of the frustum.
"""
function draw(f::Frustum, fL, P, L; color::SVec4f0 = SVec4f0(1f0, 0f0, 0f0, 1f0))
    draw(f.box_clip_space, P, L * inv(fL); color)
end
