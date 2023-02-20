using CImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using LinearAlgebra
using StaticArrays
using ModernGL
using ImageCore
using FileIO
using ImageIO
using NeuralGraphicsGL

function main()
    NeuralGraphicsGL.init()
    context = NeuralGraphicsGL.Context("でも"; width=1280, height=960, resizable=false)
    fb = NeuralGraphicsGL.Framebuffer(; width=1280, height=960)
    screen = NeuralGraphicsGL.Screen()

    bbox = NeuralGraphicsGL.BBox(zeros(SVector{3, Float32}), ones(SVector{3, Float32}))
    P = SMatrix{4, 4, Float32}(I)
    V = SMatrix{4, 4, Float32}(I)

    delta_time = 0.0
    last_time = time()
    elapsed_time = 0.0

    NeuralGraphicsGL.render_loop(context; destroy_context=false) do
        NeuralGraphicsGL.imgui_begin(context)

        NeuralGraphicsGL.bind(fb)

        NeuralGraphicsGL.enable_depth()
        NeuralGraphicsGL.set_clear_color(0.2, 0.2, 0.2, 1.0)
        NeuralGraphicsGL.clear()

        bmin = zeros(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        bmax = ones(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        NeuralGraphicsGL.update_corners!(bbox, bmin, bmax)
        NeuralGraphicsGL.draw(bbox, P, V)

        NeuralGraphicsGL.unbind(fb)

        NeuralGraphicsGL.disable_depth()
        NeuralGraphicsGL.set_clear_color(0.0, 0.0, 0.0, 1.0)
        NeuralGraphicsGL.clear(GL_COLOR_BUFFER_BIT)

        screen_texture = fb[GL_COLOR_ATTACHMENT0]
        drawed_data = NeuralGraphicsGL.get_data(screen_texture)
        save("screen.png", rotl90(colorview(RGB{N0f8}, drawed_data)))

        depth_texture = fb[GL_DEPTH_ATTACHMENT]
        depth_data = NeuralGraphicsGL.get_data(depth_texture)[1, :, :]
        save("depth.png", rotl90(colorview(Gray{Float32}, depth_data)))

        NeuralGraphicsGL.draw(screen, screen_texture)

        CImGui.Begin("UI")
        CImGui.Text("HI!")
        CImGui.End()

        NeuralGraphicsGL.imgui_end(context)
        glfwSwapBuffers(context.window)
        glfwPollEvents()

        delta_time = time() - last_time
        last_time = time()
        elapsed_time += delta_time

        false
    end

    NeuralGraphicsGL.delete!(bbox)
    NeuralGraphicsGL.delete!(screen)
    NeuralGraphicsGL.delete!(fb)
    NeuralGraphicsGL.delete!(context)
end
main()
