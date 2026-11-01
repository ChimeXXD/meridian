import Foundation

/// The artwork URLs Meridian uses for one show, picked from TVmaze's image list (D-37).
struct ShowArtwork: Hashable, Sendable {
    /// Landscape key art for heroes, near 1920 px wide so a 4K or 11K original isn't downloaded.
    var background: URL?
    /// The portrait poster at full size, for poster walls and tinting.
    var poster: URL?
    /// TVmaze's 210 × 295 poster, for rows and widgets.
    var posterThumbnail: URL?

    /// The background is AniList's banner, a strip about five times wider than tall: fine across the top of a screen,
    /// too thin to fill a widget.
    private(set) var backgroundIsStrip = false

    /// What a full-bleed hero shows: the background, or the poster when there's no background.
    var hero: URL? { background ?? poster }

    /// What the widgets save (D-46): the wide key art, unless it's a banner strip; else the full poster, which the
    /// widget art shrinks anyway; else the thumbnail.
    var widget: URL? { (backgroundIsStrip ? nil : background) ?? poster ?? posterThumbnail }

    /// The small poster beside a show in a widget's rows: the thumbnail, else the full poster; never the wide art.
    var widgetPoster: URL? { posterThumbnail ?? poster }

    static let idealBackgroundWidth = 1920
    static let minimumBackgroundWidth = 1200

    init(background: URL? = nil, poster: URL? = nil, posterThumbnail: URL? = nil) {
        (self.background, self.poster, self.posterThumbnail) = (background, poster, posterThumbnail)
    }

    /// AniList's banner as the background and its cover as the poster (D-37).
    init(media: AniListMedia) {
        self.init(background: media.bannerImage, poster: media.coverImage?.extraLarge ?? media.coverImage?.large,
                  posterThumbnail: media.coverImage?.large)
        backgroundIsStrip = true
    }

    init(images: [TVmazeImage]) {
        let backgrounds = images.filter { $0.type == "background" }
            .compactMap { image in image.resolutions["original"].map { (main: image.main, resolution: $0) } }
        // Anything under 1200 px looks soft, so a sharp background beats a soft one even if TVmaze marks the soft
        // one main; then prefer the main background, then the one closest to 1920 px.
        let score: ((main: Bool, resolution: TVmazeImage.Resolution)) -> (Int, Int, Int) = { item in
            let width = item.resolution.width ?? 0
            return (width < Self.minimumBackgroundWidth ? 1 : 0, item.main ? 0 : 1, abs(width - Self.idealBackgroundWidth))
        }
        let background = backgrounds.min { score($0) < score($1) }
        let posters = images.filter { $0.type == "poster" }
        let poster = posters.first(where: \.main) ?? posters.first
        self.init(background: background?.resolution.url, poster: poster?.resolutions["original"]?.url,
                  posterThumbnail: poster?.resolutions["medium"]?.url)
    }
}
