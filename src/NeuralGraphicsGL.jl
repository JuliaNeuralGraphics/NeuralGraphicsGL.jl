module NeuralGraphicsGL

using CImGui
using FileIO
using ImageCore
using ImageIO
using LinearAlgebra
using StaticArrays

using GLFW
using ModernGL

import CImGui.lib as lib

"""
Replaces:

```julia
id_ref = Ref{UInt32}()
glGenTextures(1, id_ref)
id = id_ref[]
```

With:

```julia

id = @ref glGenTextures(1, Ref{UInt32})
```

To pass appropriate pointer type, add `:Rep` before the regular type, e.g.
`UInt32` -> `RepUInt32`.

Replaces only first such occurrence.
"""
macro ref(expression::Expr)
    reference_position = 0
    reference_type = Nothing

    for (i, arg) in enumerate(expression.args)
        arg isa Expr || continue
        length(arg.args) < 1 && continue

        if arg.args[1] == :Ref
            reference_position = i
            reference_type = arg
            break
        end
    end
    reference_position == 0 && return esc(expression)

    expression.args[reference_position] = :reference
    esc(quote
        reference = $reference_type()
        $expression
        reference[]
    end)
end

function gl_get_error_string(e)
    if e == GL_NO_ERROR return "GL_NO_ERROR"
    elseif e == GL_INVALID_ENUM return "GL_INVALID_ENUM"
    elseif e == GL_INVALID_VALUE return "GL_INVALID_VALUE"
    elseif e == GL_INVALID_OPERATION return "GL_INVALID_OPERATION"
    elseif e == GL_STACK_OVERFLOW return "GL_STACK_OVERFLOW"
    elseif e == GL_STACK_UNDERFLOW return "GL_STACK_UNDERFLOW"
    elseif e == GL_OUT_OF_MEMORY return "GL_OUT_OF_MEMORY"
    elseif e == GL_INVALID_FRAMEBUFFER_OPERATION return "GL_INVALID_FRAMEBUFFER_OPERATION"
    elseif e == GL_CONTEXT_LOST return "GL_CONTEXT_LOST" end
    "Unknown error"
end

macro gl_check(expr)
    esc(quote
        result = $expr
        err = glGetError()
        err == GL_NO_ERROR || error("GL error: " * gl_get_error_string(err))
        result
    end)
end

const SVec2f0 = SVector{2, Float32}
const SVec3f0 = SVector{3, Float32}
const SVec4f0 = SVector{4, Float32}
const SMat3f0 = SMatrix{3, 3, Float32}
const SMat4f0 = SMatrix{4, 4, Float32}

function look_at(position, target, up; left_handed::Bool = true)
    Z = left_handed ?                # front
        normalize(position - target) :
        normalize(target - position)
    X  = normalize(normalize(up) × Z) # right
    Y = Z × X                         # up

    SMatrix{4, 4, Float32, 16}(
        X[1], Y[1], Z[1], 0f0,
        X[2], Y[2], Z[2], 0f0,
        X[3], Y[3], Z[3], 0f0,
        -(X ⋅ position), -(Y ⋅ position), -(Z ⋅ position), 1f0)
end

function _frustum(left, right, bottom, top, znear, zfar; zsign::Float32 = -1f0)
    (right == left || bottom == top || znear == zfar) &&
        return SMatrix{4, 4, Float32, 16}(I)

    rl = 1f0 / (right - left)
    tb = 1f0 / (top - bottom)
    zz = 1f0 / (zfar - znear)

    SMatrix{4, 4, Float32, 16}(
        2f0 * znear * rl, 0f0, 0f0, 0f0,
        0f0, 2f0 * znear * tb, 0f0, 0f0,
        (right + left) * rl, (top + bottom) * tb, zsign * (zfar + znear) * zz, zsign,
        0f0, 0f0, (-2f0 * znear * zfar) * zz, 0f0)
end

"""
- `fovx`: In degrees.
- `fovy`: In degrees.
"""
function perspective(fovx, fovy, znear, zfar; zsign::Float32 = -1f0)
    (znear == zfar) &&
        error("znear `$znear` must be different from zfar `$zfar`")

    w = tan(0.5f0 * deg2rad(fovx)) * znear
    h = tan(0.5f0 * deg2rad(fovy)) * znear
    _frustum(-w, w, -h, h, znear, zfar; zsign)
end

function perspective(fovy, znear, zfar; aspect::Float32, zsign::Float32 = -1f0)
    (znear == zfar) &&
        error("znear `$znear` must be different from zfar `$zfar`")

    h = tan(0.5f0 * deg2rad(fovy)) * znear
    w = h * aspect
    _frustum(-w, w, -h, h, znear, zfar; zsign)
end

abstract type AbstractTexture end

include("shader.jl")
include("texture.jl")
include("texture_array.jl")
include("buffers.jl")
include("framebuffer.jl")
include("quad.jl")
include("bounding_box.jl")
include("voxel.jl")
include("voxels.jl")
include("plane.jl")
include("line.jl")
include("frustum.jl")
include("widget.jl")

const GLSL_VERSION = 130

function init(version_major::Integer = 3, version_minor::Integer = 0)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, version_major)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, version_minor)
end

function get_gl_version()
    vmajor = @ref glGetIntegerv(GL_MAJOR_VERSION, Ref{Int32})
    vminor = @ref glGetIntegerv(GL_MINOR_VERSION, Ref{Int32})
    vmajor, vminor
end

struct Context
    window::GLFW.Window
    imgui_ctx::Ptr{CImGui.ImGuiContext}

    width::Int64
    height::Int64
end

function Context(
    title; width = -1, height = -1, fullscreen::Bool = false,
    vsync::Bool = true, resizable::Bool = true, visible::Bool = true
)
    if fullscreen && (width != -1 || height != -1)
        error("You can specify either `fullscreen` or `width` & `height` parameters.")
    end
    if !fullscreen && (width == -1 || height == -1)
        error("You need to specify either `fullscreen` or `width` & `height` parameters.")
    end

    imgui_ctx = CImGui.CreateContext()

    GLFW.Init()
    GLFW.WindowHint(GLFW.VISIBLE, visible)

    window = if fullscreen
        GLFW.WindowHint(GLFW.RESIZABLE, false)
        monitor = GLFW.GetPrimaryMonitor()
        mode = GLFW.GetVideoMode(monitor)

        width, height = mode.width, mode.height
        GLFW.CreateWindow(width, height, title, monitor)
    else
        GLFW.WindowHint(GLFW.RESIZABLE, resizable)
        GLFW.CreateWindow(width, height, title)
    end
    @assert window != C_NULL

    GLFW.MakeContextCurrent(window)
    GLFW.SwapInterval(vsync ? 1 : 0)

    # Setup Platform/Renderer bindings.
    lib.ImGui_ImplGlfw_InitForOpenGL(Ptr{lib.GLFWwindow}(window.handle), true)
    lib.ImGui_ImplOpenGL3_Init("#version $GLSL_VERSION")

    # You need this for RGB textures that their width is not a multiple of 4.
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)

    # Enable depth buffer.
    glEnable(GL_DEPTH_TEST)
    glDepthMask(GL_TRUE)
    glClearDepth(1.0f0)

    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    # Set ImGui syle.
    CImGui.StyleColorsDark()
    style = CImGui.GetStyle()
    style.FrameRounding = 0f0
    style.WindowRounding = 0f0
    style.ScrollbarRounding = 0f0

    io = CImGui.GetIO()
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable

    Context(window, imgui_ctx, width, height)
end

enable_blend() = glEnable(GL_BLEND)

disable_blend() = glDisable(GL_BLEND)

enable_depth() = glEnable(GL_DEPTH_TEST)

disable_depth() = glDisable(GL_DEPTH_TEST)

enable_wireframe() = glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)

disable_wireframe() = glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)

function delete!(c::Context)
    imgui_shutdown!(c)
    GLFW.DestroyWindow(c.window)
end

function set_resizable_window!(c::Context, resizable::Bool)
    GLFW.SetWindowAttrib(c.window, GLFW.RESIZABLE, resizable)
end

function set_resize_callback!(c::Context, callback)
    GLFW.SetWindowSizeCallback(c.window, callback)
end

function imgui_begin()
    lib.ImGui_ImplOpenGL3_NewFrame()
    lib.ImGui_ImplGlfw_NewFrame()
    CImGui.NewFrame()
end

function imgui_end()
    CImGui.Render()
    lib.ImGui_ImplOpenGL3_RenderDrawData(Ptr{Cint}(CImGui.GetDrawData()))
end

function imgui_shutdown!(c::Context)
    lib.ImGui_ImplOpenGL3_Shutdown()
    lib.ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(c.imgui_ctx)
end

clear(bit::UInt32 = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) = glClear(bit)

set_clear_color(r, g, b, a) = glClearColor(r, g, b, a)

set_viewport(width, height) = glViewport(0, 0, width, height)

hide_cursor(w::GLFW.Window) = GLFW.SetInputMode(w, GLFW.CURSOR, GLFW.CURSOR_DISABLED)

show_cursor(w::GLFW.Window) = GLFW.SetInputMode(w, GLFW.CURSOR, GLFW.CURSOR_NORMAL)

function render_loop(draw_function, c::Context; destroy_context::Bool = true)
    try
        while GLFW.WindowShouldClose(c.window) == 0
            is_running = draw_function()
            is_running || break
        end
    catch exception
        @error "Error in render loop!" exception=exception
        Base.show_backtrace(stderr, catch_backtrace())
    finally
        destroy_context && delete!(c)
    end
end

is_key_pressed(key; repeat::Bool = true) = CImGui.IsKeyPressed(key, repeat)

is_key_down(key) = CImGui.IsKeyDown(key)

get_mouse_delta() = unsafe_load(CImGui.GetIO().MouseDelta)

function resize_callback(_, width, height)
    (width == 0 || height == 0) && return nothing # Window minimized.
    set_viewport(width, height)
    nothing
end

end
