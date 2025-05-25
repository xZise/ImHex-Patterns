#pragma author xZise
#pragma description World DB file for Lego Island
#pragma endian little

import std.string;
import std.mem;
import std.io;
import std.core;
import type.color;

using Color = type::RGB8 [[hex::inline_visualize("color", r, g, b, 0xff)]];

fn format_vector3f(auto vector) {
    return std::format("x={:.2f}, y={:.2f}, z={:.2f}", vector.x, vector.y, vector.z);
};

struct Vector3f {
    float x;
    float y;
    float z;
} [[static, format("format_vector3f")]];

fn format_named(auto named_ref) {
    return std::format("{0} (Size: {1})", named_ref.name, named_ref.size);
};

struct PartRef {
    std::string::SizedString<u32> name;
    u32 size;
    u32 offset;
} [[format("format_named")]];

struct ModelRef {
    std::string::SizedString<u32> name;
    u32 size;
    u32 offset;
    std::string::SizedString<u32> texture_name;
    Vector3f location;
    Vector3f direction;
    Vector3f up;
    padding[1];
} [[format("format_named")]];

fn format_world(auto world) {
    return std::format("{0} (Parts: {1}, Models: {2})", world.name, world.num_parts, world.num_models);
};

struct World {
    std::string::SizedString<u32> name;
    u32 num_parts;
    PartRef parts[num_parts];
    u32 num_models;
    ModelRef models[num_models];
} [[format("format_world")]];

struct Gif {
    u32 width;
    u32 height;
    u32 num_colors;
    Color colors[num_colors];
    u8 image[width * height];
};

struct NamedGif {
    std::string::SizedString<u32> name;
    Gif gif [[inline]];
};

struct WDB {
    u32 num_worlds;
    World worlds[num_worlds];
    u32 gif_chunk_size;
    u32 num_frames;
    NamedGif frames[num_frames];
};

WDB wdb @ 0;
