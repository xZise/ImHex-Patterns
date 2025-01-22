#pragma endian little
#pragma magic [12 AF] @ 0x4

import std.mem;
import std.core;
import std.io;
import type.color;

using Color = type::RGB<8, 8, 8> [[hex::inline_visualize("color", r, g, b, 0xff)]];

enum FlicType : u16 {
    FLI = 0xAF11,
    FLC_8bit = 0xAF12,
    FLIC_other = 0xAF44,
    FLIC_Huffmann = 0xAF30,
    FLIC_frame_shift = 0xAF31,
};

enum ChunkType : u16 {
    CEL_DATA = 3,               // Registration and transparency
    COLOR_256 = 4,              // 256-level colour palette
    DELTA_FLC = 7,              // Delta image, word oriented RLE (FLI_SS2)
    COLOR_64 = 11,              // 64-level colour palette
    DELTA_FLI = 12,             // Delta image, byte oriented RLE (FLI_LC)
    BLACK = 13,                 // Full black frame (rare)
    BYTE_RUN = 15,              // Full image, byte oriented RLE (FLI_BRUN)
    FLI_COPY = 16,              // Uncompressed image (rare)
    PSTAMP = 18,                // Postage stamp (icon of the first frame)
    DTA_BRUN = 25,              // Full image, pixel oriented RLE
    DTA_COPY = 26,              // Uncompressed image
    DTA_LC = 27,                // Delta image, pixel oriented RLE
    LABEL = 31,                 // Frame label
    BMP_MASK = 32,              // Bitmap mask
    MLEV_MASK = 33,             // Multilevel mask
    SEGMENT = 34,               // Segment information
    KEY_IMAGE = 35,             // Key image, similar to BYTE_RUN / DTA_BRUN
    KEY_PAL = 36,               // Key palette, similar to COLOR_256
    REGION = 37,                // Region of frame differences
    WAVE = 38,                  // Digitized audio
    USERSTRING = 39,            // General purpose user data
    RGN_MASK = 40,              // Region mask
    LABELEX = 41,               // Extended frame label (includes symbolic name)
    SHIFT = 42,                 // Scanline delta shifts (compression)
    PATHMAP = 43,               // Path map (segment transitions)

    PREFIX_TYPE = 0xF100,       // Prefix chunk
    SCRIPT_CHUNK = 0xF1E0,      // Embedded "Small" script
    FRAME_TYPE = 0xF1FA,        // Frame chunk
    SEGMENT_TABLE = 0xF1FB,     // Segment table chunk
    HUFFMAN_TABLE = 0xF1FC      // Huffman compression table chunk
};

u16 pixels_per_line = 0;
u16 lines = 0;

struct Header {
    u32 size;
    FlicType type;
    u16 frames;
    u16 width;
    u16 height;
    u16 depth;
    u16 flags;
    u32 speed;
    u16 reserved1;
    u32 created;
    u32 creator;
    u32 updated;
    u32 updater;
    u16 aspect_dx;
    u16 aspect_dy;
    u16 ext_flags;
    u16 keyframes;
    u16 totalframes;
    u32 req_memory;
    u16 max_regions;
    u16 transp_num;
    u8  reserved2[24];
    u32 oframe1;
    u32 oframe2;
    u8  reserved3[40];

    pixels_per_line = width;
    lines = height;
};

namespace DeltaFLCChunk {
    enum OpcodeType : u8 {
        Count = 0b00,
        Undefined = 0b01,
        LowByte = 0b10,
        LineSkipCount = 0b11,
    };

    struct Packet {
        u8 data_count = 0;

        u8 skip_count;
        s8 count;
        if (count < 0) {
            data_count = 1;
        } else {
            data_count = count;
        }
        u8 data[data_count * 2];
    };

    u16 packets_in_line;

    bitfield Opcode {
        value: 14;
        OpcodeType type: 2;

        if (type == OpcodeType::Count) {
            packets_in_line = value;
            break;
        }
    };

    struct Line {
        packets_in_line = 0;
        Opcode opcodes[while(true)];
        Packet packets[packets_in_line];
    };
}

namespace ByteRunChunk {
    u16 pixels_in_line_counter = 0;

    struct Packet {
        u8 data_count = 0;

        s8 count;
        if (count < 0) {
            data_count = -count;
            pixels_in_line_counter = data_count + pixels_in_line_counter;
        } else {
            data_count = 1;
            pixels_in_line_counter = count + pixels_in_line_counter;
        }
        u8 data[data_count];
    };

    struct Line {
        pixels_in_line_counter = 0;
        u8 packet_count;
        Packet packets[while(pixels_in_line_counter < pixels_per_line)];
    };
}

struct ColorPalettePacket {
    u8 skip;
    u8 copy;
    if (copy == 0) {
        Color color[256];
    } else {
        Color color[copy];
    }
};

struct Chunk {
    u32 size;
    ChunkType type;

    if (type == ChunkType::FRAME_TYPE) {
        u16 chunks;
        u16 delay;
        u16 reserved;
        u16 width;
        u16 height;
        // Not sure if this is the intended operation here?
        if (width > 0) {
            pixels_per_line = width;
        }
        if (height > 0) {
            lines = height;
        }
        Chunk subchunks[chunks];
    } else if (type == ChunkType::COLOR_256) {
        u16 num_packets;
        ColorPalettePacket packets[num_packets];
    } else if (type == ChunkType::BYTE_RUN) {
        ByteRunChunk::Line lines[lines];
    } else if (type == ChunkType::DELTA_FLC) {
        u16 line_count;
        DeltaFLCChunk::Line lines[line_count];
    }
    // When the chunk size is rounded up to the next even number, it might need a padding byte.
    // Unrecognized chunk types will also fill out the padding
    padding[size - ($ - addressof(this))];
};

Header header @ $;
Chunk chunks[while(!std::mem::eof())] @ $;