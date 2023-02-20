using CImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using LinearAlgebra
using StaticArrays
using NeuralGraphicsGL

function main()
    NeuralGraphicsGL.init()
    context = NeuralGraphicsGL.Context("でも"; width=1280, height=960)
    NeuralGraphicsGL.set_resize_callback!(context, NeuralGraphicsGL.resize_callback)

    bbox = NeuralGraphicsGL.Box(zeros(SVector{3, Float32}), ones(SVector{3, Float32}))
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
    voxels = NeuralGraphicsGL.Voxels(Float32[])

    NeuralGraphicsGL.enable_blend()

    NeuralGraphicsGL.render_loop(context; destroy_context=false) do
        NeuralGraphicsGL.imgui_begin(context)
        NeuralGraphicsGL.clear()
        NeuralGraphicsGL.set_clear_color(0.2, 0.2, 0.2, 1.0)

        # bmin = zeros(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        # bmax = ones(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        # NeuralGraphicsGL.update_corners!(bbox, bmin, bmax)
        # NeuralGraphicsGL.draw(bbox, P, V)

        NeuralGraphicsGL.draw_instanced(voxels, P, V)

        if 2 < elapsed_time < 4
            NeuralGraphicsGL.update!(voxels, voxels_data_2)
        elseif elapsed_time > 4
            NeuralGraphicsGL.update!(voxels, voxels_data)
        end

        CImGui.Begin("UI")
        CImGui.Text("HI!")
        CImGui.End()

        NeuralGraphicsGL.imgui_end(context)
        glfwSwapBuffers(context.window)
        glfwPollEvents()

        delta_time = time() - last_time
        last_time = time()
        elapsed_time += delta_time
        true
    end

    NeuralGraphicsGL.delete!(voxels)
    NeuralGraphicsGL.delete!(bbox)
    NeuralGraphicsGL.delete!(context)
end
main()
