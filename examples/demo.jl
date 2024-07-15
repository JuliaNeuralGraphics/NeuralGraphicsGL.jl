using CImGui
using GLFW
using LinearAlgebra
using StaticArrays
using NeuralGraphicsGL

import NeuralGraphicsGL as NGL

function main()
    NGL.init()
    context = NGL.Context("でも"; width=1280, height=960)
    NGL.set_resize_callback!(context, NGL.resize_callback)

    bbox = NGL.Box(zeros(SVector{3, Float32}), ones(SVector{3, Float32}))
    P = SMatrix{4, 4, Float32}(I)
    V = SMatrix{4, 4, Float32}(I)

    delta_time = 0.0
    last_time = time()
    elapsed_time = 0.0

    voxels_data = Float32[
        0f0, 0f0, 0f0, 1f0, 0.1f0,
        0.2f0, 0f0, 0f0, 0.5f0, 0.1f0,
        0.2f0, 0.2f0, 0f0, 0f0, 0.05f0]
    voxels_data_2 = Float32[
        0f0, 0f0, 0f0, 1f0, 0.1f0,
        0.2f0, 0f0, 0f0, 0.5f0, 0.1f0]
    voxels = NGL.Voxels(Float32[])

    NGL.enable_blend()

    NGL.render_loop(context; destroy_context=false) do
        NGL.imgui_begin()
        NGL.clear()
        NGL.set_clear_color(0.2, 0.2, 0.2, 1.0)

        # bmin = zeros(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        # bmax = ones(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        # NGL.update_corners!(bbox, bmin, bmax)
        # NGL.draw(bbox, P, V)

        NGL.draw_instanced(voxels, P, V)

        if 2 < elapsed_time < 4
            NGL.update!(voxels, voxels_data_2)
        elseif elapsed_time > 4
            NGL.update!(voxels, voxels_data)
        end

        CImGui.Begin("UI")
        CImGui.Text("HI!")
        CImGui.End()

        NGL.imgui_end()
        GLFW.SwapBuffers(context.window)
        GLFW.PollEvents()

        delta_time = time() - last_time
        last_time = time()
        elapsed_time += delta_time
        true
    end

    NGL.delete!(voxels)
    NGL.delete!(bbox)
    NGL.delete!(context)
end
main()
