const std = @import("std");
const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "");
    @cDefine("IMGUI_DEFINE_MATH_OPERATORS", "");
    @cDefine("CIMGUI_USE_SDL2", "");
    @cInclude("SDL.h");
    @cInclude("stdarg.h");
    @cInclude("cimgui.h");
    @cInclude("cimguizmo.h");
    @cInclude("cimgui_impl.h");
});

const SdlErrors = error{ InitializationError, WindowCreationError };

pub fn main() !void {
    const screen_width = 1280;
    const screen_height = 720;

    const imgui_version = c.igGetVersion();
    std.debug.print("imgui version {s}", .{imgui_version});

    var window: ?*c.SDL_Window = null;

    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_TIMER) < 0) {
        std.debug.print("Failed to initialize SDL2", .{});
        return SdlErrors.InitializationError;
    }

    window = c.SDL_CreateWindow("SDL tutorial", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, screen_width, screen_height, c.SDL_WINDOW_SHOWN);

    if (window == null) {
        std.debug.print("Failed to create sdl2 window", .{});
        return SdlErrors.WindowCreationError;
    }

    var renderer: ?*c.SDL_Renderer = null;

    renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_PRESENTVSYNC | c.SDL_RENDERER_ACCELERATED);

    const ig_context = c.igCreateContext(null);

    const io = c.igGetIO();
    io.*.ConfigFlags |= c.ImGuiConfigFlags_NavEnableKeyboard;

    c.igStyleColorsDark(null);

    _ = c.ImGui_ImplSDL2_InitForSDLRenderer(window, renderer);
    _ = c.ImGui_ImplSDLRenderer2_Init(renderer);

    var event: c.SDL_Event = undefined;
    var quit: bool = false;
    while (quit == false) {
        while (c.SDL_PollEvent(&event) > 0) {
            _ = c.ImGui_ImplSDL2_ProcessEvent(&event);

            if (event.type == c.SDL_QUIT)
                quit = true;
        }

        // var my_tool_active: bool = true;
        // _ = c.igBegin("My First Tool", &my_tool_active, c.ImGuiWindowFlags_MenuBar);
        //
        // if (c.igBeginMenuBar()) {
        //     if (c.igBeginMenu("File", true)) {
        //         if (c.igMenuItem_Bool("Open..", "Ctrl+O", false, true)) {}
        //         if (c.igMenuItem_Bool("Save..", "Ctrl+S", false, true)) {}
        //         if (c.igMenuItem_Bool("Close..", "Ctrl+W", false, true)) {
        //             my_tool_active = false;
        //         }
        //         c.igEndMenu();
        //     }
        // }
        // c.igEndMenuBar();
        //
        // var color: [3]f32 = .{ 128.0, 128.0, 128.0 };
        // _ = c.igColorEdit3("Color", &color, c.ImGuiColorEditFlags_None);
        //
        // var samples: [100]f32 = .{0.0} ** 100;
        // for (0..100) |i| {
        //     samples[i] = std.math.sin(@as(f32, @floatFromInt(i)) * 0.2 + @as(f32, @floatCast(c.igGetTime())) * 1.5);
        // }
        //
        // _ = c.igPlotLines_FloatPtr("Samples", &samples, 100, 0, null, 0, 100, .{}, 1);
        //
        // _ = c.igTextColored(c.ImVec4_ImVec4_Float(1.0, 1.0, 0.0, 1.0).*, "Important Stuff");
        //
        // _ = c.igBeginChild_Str("Scrolling", c.ImVec2_ImVec2_Float(30.0, 100.0).*, c.ImGuiChildFlags_None, c.ImGuiWindowRefreshFlags_None);
        // for (0..50) |i| {
        //     c.igText("%04d: Some text", i);
        // }
        // c.igEndChild();
        // c.igEnd();
        //c.igRender();

        c.ImGui_ImplSDLRenderer2_NewFrame();
        c.ImGui_ImplSDL2_NewFrame();
        c.igNewFrame();

        var show_windows: bool = true;
        c.igShowDemoWindow(&show_windows);

        c.igRender();
        _ = c.SDL_RenderSetScale(renderer, io.*.DisplayFramebufferScale.x, io.*.DisplayFramebufferScale.y);
        _ = c.SDL_SetRenderDrawColor(renderer, 128, 255, 128, 255);
        _ = c.SDL_RenderClear(renderer);
        c.ImGui_ImplSDLRenderer2_RenderDrawData(c.igGetDrawData(), renderer);
        c.SDL_RenderPresent(renderer);
    }

    c.ImGui_ImplSDLRenderer2_Shutdown();
    c.ImGui_ImplSDL2_Shutdown();
    c.igDestroyContext(ig_context);

    c.SDL_DestroyRenderer(renderer);
    c.SDL_DestroyWindow(window);
    c.SDL_Quit();
}
