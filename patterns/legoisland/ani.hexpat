#pragma author xZise
#pragma description Animation file for Lego Island
#pragma endian little

import std.io;
import std.string;

import legoisland.common;
import legoisland.animation;

struct Animation<auto ParseScene> {
    std::string::SizedString<u32> name;
    if (name.size > 0) {
        u32 unknown;
    }
    s32 duration;

    if (ParseScene) {
        std::unimplemented();
    }

    AnimationNode animation;
};

struct Anim {
    s32 magic;
    float unknown1;
    Vector3f unknownVector;
    s32 parse_scene;
    s32 val3;
    u32 num_animations;
    Animation<parse_scene != 0> animations[num_animations];
};

Anim a @ 0;