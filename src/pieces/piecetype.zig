pub const PieceType = enum(u8) {
    none = 0,
    pawn = 1, // Standard pawn :contentReference[oaicite:0]{index=0}
    rook = 2, // Standard rook :contentReference[oaicite:1]{index=1}
    knight = 3, // Standard knight :contentReference[oaicite:2]{index=2}
    bishop = 4, // Standard bishop :contentReference[oaicite:3]{index=3}
    queen = 5, // Standard queen :contentReference[oaicite:4]{index=4}
    king = 6, // Standard king :contentReference[oaicite:5]{index=5}

    // Chess‐piece compounds :contentReference[oaicite:6]{index=6}
    amazon = 7, // Queen + Knight
    archbishop = 8, // Bishop + Knight
    chancellor = 9, // Rook + Knight
    crowned_knight = 10, // King + Knight
    crowned_rook = 11, // King + Rook
    crowned_bishop = 12, // King + Bishop
    dragon = 13, // Pawn + Knight

    // Elementary leapers :contentReference[oaicite:7]{index=7}
    alfil = 14, // (2,2)-leaper
    antelope = 15, // (3,4)-leaper
    camel = 16, // (1,3)-leaper
    dabbabah = 17, // (0,2)-leaper
    ferz = 18, // (1,1)-leaper
    flamingo = 19, // (1,6)-leaper
    giraffe = 20, // (1,4)-leaper
    wazir = 21, // (0,1)-leaper
    zebra = 22, // (2,3)-leaper

    // Double‐leaper compounds :contentReference[oaicite:8]{index=8}
    alibaba = 23, // Alfil + Dabbabah
    bison = 24, // Camel + Zebra
    carpenter = 25, // Knight + Dabbabah
    gnu = 26, // Knight + Camel
    kangaroo = 27, // Knight + Alfil
    man = 28, // Ferz + Wazir
    okapi = 29, // Knight + Zebra
    phoenix = 30, // Wazir + Alfil
    root50_leaper = 31, // 5-5 + 1-7 leaper
    wizard = 32, // Camel + Ferz

    // Triple‐leaper compounds :contentReference[oaicite:9]{index=9}
    buffalo = 33, // Knight + Camel + Zebra
    centaur = 34, // Ferz + Wazir + Knight
    champion = 35, // Wazir + Dabbabah + Alfil
    fad = 36, // Ferz + Alfil + Dabbabah
    squirrel = 37, // Alfil + Dabbabah + Knight

    // Asymmetric leapers :contentReference[oaicite:10]{index=10}
    barc = 38, // Reverse Crab
    crab = 39, // Narrow/Wide Knight variation
    fibnif = 40, // Ferz + narrow Knight
    gold_general = 41, // Wazir or forward one
    honorable_horse = 42, // Shogi‐style knight
    mushroom = 43, // Mixed narrow/wide leaps
    silver_general = 44, // Ferz or forward one

    // Divergent & double leapers :contentReference[oaicite:11]{index=11}
    lion_murray = 45, // Divergent leaper (Murray)
    lion_chu = 46, // Double leaper (Chu Shogi)

    // Elementary riders :contentReference[oaicite:12]{index=12}
    bishop_rider = 47, // (1,1) rider
    camelrider = 48, // (1,3) rider
    nightrider = 49, // Extended Knight rider
    rook_rider = 50, // (0,1) rider
    unicorn_3d = 51, // (1,1,1) 3D rider
    zebrarider = 52, // (2,3) rider

    // Asymmetric riders :contentReference[oaicite:13]{index=13}
    lance = 53, // Rook forward only
    zag_zag = 54, // Horizontal + NE-SW
    zag_zig = 55, // Vertical + NW-SE
    zig_zag = 56, // Horizontal + NE-SW
    zig_zig = 57, // Horizontal + NW-SE

    // Restricted riders :contentReference[oaicite:14]{index=14}
    edgehog = 58, // Queen‐lines to/from edge
    sissa = 59, // Rook-Step+Bishop-Step equal
    soucie = 60, // Queen‐lines count pieces

    // Reflectors & curved riders :contentReference[oaicite:15]{index=15}
    archbishop_reflecting = 61, // Reflecting bishop
    bishop_reflecting = 62, // Multi‐reflect bishop
    crooked_bishop = 63, // Zigzag diagonal
    rose = 64, // Circular knight moves
    windmill = 65, // Orbital rider
    ubi_ubi = 66, // Free Knight‐rider

    // Double‐rider compounds :contentReference[oaicite:16]{index=16}
    crooked_queen = 67, // Rook + Crooked Bishop
    raven = 68, // Rook + Nightrider
    unicorn_compound = 69, // Bishop + Nightrider

    // Hoppers :contentReference[oaicite:17]{index=17}
    bishopper = 70, // Diagonal hopper
    contragrasshopper = 71, // Queen‐hopping only
    equihopper = 72, // Symmetric hopper
    grasshopper = 73, // Queen‐hopper
    kangaroo_hopper = 74, // Double‐hopping queen
    mao_hopper = 75, // Knight with hurdle
    nonstop_equihopper = 76, // Multiple equihopping
    lion_hopper = 77, // Queen‐hopper compound
};

pub fn toString(piece_type: PieceType) []const u8 {
    return switch (piece_type) {
        .none => "None",
        .pawn => "Pawn",
        .rook => "Rook",
        .knight => "Knight",
        .bishop => "Bishop",
        .queen => "Queen",
        .king => "King",
        .amazon => "Amazon",
        .archbishop => "Archbishop",
        .chancellor => "Chancellor",
        .crowned_knight => "Crowned Knight",
        .crowned_rook => "Crowned Rook",
        .crowned_bishop => "Crowned Bishop",
        .dragon => "Dragon",
        .alfil => "Alfil",
        .antelope => "Antelope",
        .camel => "Camel",
        .dabbabah => "Dabbabah",
        .ferz => "Ferz",
        .flamingo => "Flamingo",
        .giraffe => "Giraffe",
        .wazir => "Wazir",
        .zebra => "Zebra",
        .alibaba => "Alibaba",
        .bison => "Bison",
        .carpenter => "Carpenter",
        .gnu => "Gnu",
        .kangaroo => "Kangaroo",
        .koala => "Koala",
        .lion => "Lion",
        .man => "Man",
        .okapi => "Okapi",
        .phoenix => "Phoenix",
        .root50_leaper => "Root50 Leaper",
        .wizard => "Wizard",
        .buffalo => "Buffalo",
        .centaur => "Centaur",
        .champion => "Champion",
        .fad => "Fad",
        .squirrel => "Squirrel",
        .barc => "Barc",
        .crab => "Crab",
        .fibnif => "Fibnif",
        .gold_general => "Gold General",
        .honorable_horse => "Honorable Horse",
        .mushroom => "Mushroom",
        .silver_general => "Silver General",
        .lion_murray => "Lion Murray",
        .lion_chu => "Lion Chu",
        .bishop_rider => "Bishop Rider",
        .camelrider => "Camelrider",
        .nightrider => "Nightrider",
        .rook_rider => "Rook Rider",
        .unicorn_3d => "Unicorn 3D",
        .zebrarider => "Zebrarider",
        .lance => "Lance",
        .zag_zag => "Zag Zag",
        .zag_zig => "Zag Zig",
        .zig_zag => "Zig Zag",
        .zig_zig => "Zig Zig",
        .edgehog => "Edgehog",
        .sissa => "Sissa",
        .soucie => "Soucie",
        .archbishop_reflecting => "Archbishop Reflecting",
        .bishop_reflecting => "Bishop Reflecting",
        .crooked_bishop => "Crooked Bishop",
        .rose => "Rose",
        .windmill => "Windmill",
        .ubi_ubi => "Ubi Ubi",
        .crooked_queen => "Crooked Queen",
        .raven => "Raven",
        .unicorn_compound => "Unicorn Compound",
        .bishopper => "Bishopper",
        .contragrasshopper => "Contragrasshopper",
        .equihopper => "Equihopper",
        .grasshopper => "Grasshopper",
        .kangaroo_hopper => "Kangaroo Hopper",
        .mao_hopper => "Mao Hopper",
        .nonstop_equihopper => "Nonstop Equihopper",
        .lion_hopper => "Lion Hopper",
    };
}
