#pragma author xZise
#pragma description Animation types used in ani and wdb files
#pragma endian little

import std.string;

import legoisland.common;

bitfield TimeAndFlags {
  flags: 8;
  time: 24;
};

struct VertexKey {
    TimeAndFlags timeAndFlags;
    Vector3f vertex;
};

struct RotationKey {
    TimeAndFlags timeAndFlags;
    float w;
    float x;
    float y;
    float z;
};

struct MorphKey {
    TimeAndFlags timeAndFlags;
    u8 some_bool;
};

struct AnimationNode {
    std::string::SizedString<u32> name;
    u16 num_translations;
    VertexKey translations[num_translations];
    u16 num_rotations;
    RotationKey rotations[num_rotations];
    u16 num_scales;
    VertexKey scales[num_scales];
    u16 num_morphs;
    MorphKey morphs[num_morphs];
    u32 num_children;
    AnimationNode children[num_children];
};