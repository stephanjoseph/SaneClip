import SwiftUI
import WidgetKit

@main
struct SaneClipIOSWidgets: WidgetBundle {
    var body: some Widget {
        RecentClipsIOSWidget()
        PinnedClipsIOSWidget()
    }
}
