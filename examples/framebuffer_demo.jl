using CImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using LinearAlgebra
using StaticArrays
using ModernGL
using ImageCore
using FileIO
using ImageIO
using NeuralGraphicsGL

import NeuralGraphicsGL as NGL

function main()
    NGL.init()
    context = NGL.Context("でも"; width=1280, height=960, resizable=false)
    fb = NGL.Framebuffer(; width=1280, height=960)
    screen = NGL.Screen()

    bbox = NGL.BBox(zeros(SVector{3, Float32}), ones(SVector{3, Float32}))
    frustum = NGL.Frustum()
    P = SMatrix{4, 4, Float32}(I)
    V = SMatrix{4, 4, Float32}(I)

    delta_time = 0.0
    last_time = time()
    elapsed_time = 0.0

    NGL.render_loop(context; destroy_context=false) do
        NGL.imgui_begin(context)

        NGL.bind(fb)

        NGL.enable_depth()
        NGL.set_clear_color(0.2, 0.2, 0.2, 1.0)
        NGL.clear()

        bmin = zeros(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        bmax = ones(SVector{3, Float32}) .- Float32(delta_time) * 5f0
        NGL.update_corners!(bbox, bmin, bmax)
        NGL.draw(bbox, P, V; color=SVector{4, Float32}(0f0, 1f0, 0f0, 1f0))
        NGL.draw(frustum, V, P, V; color=SVector{4, Float32}(0f0, 1f0, 0f0, 1f0))

        NGL.unbind(fb)

        NGL.disable_depth()
        NGL.set_clear_color(0.0, 0.0, 0.0, 1.0)
        NGL.clear(GL_COLOR_BUFFER_BIT)

        screen_texture = fb[GL_COLOR_ATTACHMENT0]
        drawed_data = NGL.get_data(screen_texture)
        save("screen.png", rotl90(colorview(RGB{N0f8}, drawed_data)))

        depth_texture = fb[GL_DEPTH_ATTACHMENT]
        depth_data = NGL.get_data(depth_texture)[1, :, :]
        save("depth.png", rotl90(colorview(Gray{Float32}, depth_data)))

        NGL.draw(screen, screen_texture)

        CImGui.Begin("UI")
        CImGui.Text("HI!")
        CImGui.End()

        NGL.imgui_end(context)
        glfwSwapBuffers(context.window)
        glfwPollEvents()

        delta_time = time() - last_time
        last_time = time()
        elapsed_time += delta_time

        false
    end

    NGL.delete!(bbox)
    NGL.delete!(screen)
    NGL.delete!(fb)
    NGL.delete!(context)
end
main()
