using Test
using StaticArrays
using ModernGL
using NeuralGraphicsGL

NeuralGraphicsGL.init(4, 4)

function in_gl_ctx(test_function)
    ctx = NeuralGraphicsGL.Context("Test"; width=64, height=64)
    test_function()
    NeuralGraphicsGL.delete!(ctx)
end

@testset "Resize texture" begin
    in_gl_ctx() do
        t = NeuralGraphicsGL.Texture(2, 2)
        @test t.id > 0
        old_id = t.id

        new_width, new_height = 4, 4
        NeuralGraphicsGL.resize!(t; width=new_width, height=new_height)

        @test t.id == old_id
        @test t.width == new_width
        @test t.height == new_height

        NeuralGraphicsGL.delete!(t)
    end
end

@testset "Test OP on deleted texture" begin
    in_gl_ctx() do
        t = NeuralGraphicsGL.Texture(2, 2)
        @test t.id > 0
        NeuralGraphicsGL.delete!(t)
        new_width, new_height = 4, 4
        @test_throws ErrorException NeuralGraphicsGL.resize!(
            t; width=new_width, height=new_height)
    end
end

@testset "Read & write texture" begin
    in_gl_ctx() do
        t = NeuralGraphicsGL.Texture(4, 4)
        @test t.id > 0

        data = rand(UInt8, 3, t.width, t.height)
        NeuralGraphicsGL.set_data!(t, data)

        tex_data = NeuralGraphicsGL.get_data(t)
        @test size(data) == size(tex_data)
        @test data == tex_data

        NeuralGraphicsGL.delete!(t)
    end
end

@testset "Read & write texture array" begin
    in_gl_ctx() do
        t = NeuralGraphicsGL.TextureArray(4, 4, 4)
        @test t.id > 0

        data = rand(UInt8, 3, t.width, t.height, t.depth)
        NeuralGraphicsGL.set_data!(t, data)

        tex_data = NeuralGraphicsGL.get_data(t)
        @test size(data) == size(tex_data)
        @test data == tex_data

        NeuralGraphicsGL.delete!(t)
    end
end

@testset "Resize texture array" begin
    in_gl_ctx() do
        t = NeuralGraphicsGL.TextureArray(2, 2, 2)
        @test t.id > 0
        old_id = t.id

        new_width, new_height, new_depth = 4, 4, 4
        NeuralGraphicsGL.resize!(t; width=new_width, height=new_height, depth=new_depth)

        @test t.id == old_id
        @test t.width == new_width
        @test t.height == new_height
        @test t.depth == new_depth

        NeuralGraphicsGL.delete!(t)
    end
end

@testset "Framebuffer creation" begin
    in_gl_ctx() do
        fb = NeuralGraphicsGL.Framebuffer(Dict(
            GL_COLOR_ATTACHMENT0 => NeuralGraphicsGL.TextureArray(0, 0, 0),
            GL_DEPTH_STENCIL_ATTACHMENT => NeuralGraphicsGL.TextureArray(0, 0, 0)))
        @test fb.id > 0
        @test length(fb.attachments) == 2
        @test NeuralGraphicsGL.is_complete(fb)

        NeuralGraphicsGL.delete!(fb)
    end
end

@testset "Line creation" begin
    in_gl_ctx() do
        l = NeuralGraphicsGL.Line(zeros(SVector{3, Float32}), ones(SVector{3, Float32}))
        @test l.va.id > 0
        NeuralGraphicsGL.delete!(l; with_program=true)
    end
end

@testset "IndexBuffer creation, update, read" begin
    in_gl_ctx() do
        idx1 = UInt32[0, 1, 2, 3]
        idx2 = UInt32[0, 1, 2, 3, 4, 5, 6, 7]
        idx3 = UInt32[0, 1]

        ib = NeuralGraphicsGL.IndexBuffer(idx1; primitive_type=GL_LINES, usage=GL_DYNAMIC_DRAW)
        @test length(ib) == length(idx1)
        @test sizeof(ib) == sizeof(idx1)
        @test NeuralGraphicsGL.get_data(ib) == idx1

        NeuralGraphicsGL.set_data!(ib, idx2)
        @test length(ib) == length(idx2)
        @test sizeof(ib) == sizeof(idx2)
        @test NeuralGraphicsGL.get_data(ib) == idx2

        NeuralGraphicsGL.set_data!(ib, idx3)
        @test length(ib) == length(idx3)
        @test sizeof(ib) == sizeof(idx3)
        @test NeuralGraphicsGL.get_data(ib) == idx3
    end
end

@testset "VertexBuffer creation, update, read" begin
    in_gl_ctx() do
        v1 = rand(Float32, 3, 1)
        v2 = rand(Float32, 3, 4)
        v3 = rand(Float32, 3, 2)

        layout = NeuralGraphicsGL.BufferLayout([
            NeuralGraphicsGL.BufferElement(SVector{3, Float32}, "position")])
        vb = NeuralGraphicsGL.VertexBuffer(v1, layout; usage=GL_DYNAMIC_DRAW)
        @test length(vb) == length(v1)
        @test sizeof(vb) == sizeof(v1)
        @test NeuralGraphicsGL.get_data(vb) == reshape(v1, :)

        NeuralGraphicsGL.set_data!(vb, v2)
        @test length(vb) == length(v2)
        @test sizeof(vb) == sizeof(v2)
        @test NeuralGraphicsGL.get_data(vb) == reshape(v2, :)

        NeuralGraphicsGL.set_data!(vb, v3)
        @test length(vb) == length(v3)
        @test sizeof(vb) == sizeof(v3)
        @test NeuralGraphicsGL.get_data(vb) == reshape(v3, :)
    end
end
