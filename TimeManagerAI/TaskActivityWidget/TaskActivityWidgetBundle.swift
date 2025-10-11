import WidgetKit
import SwiftUI

@main
struct TaskActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            TaskActivityWidget()
        }
    }
}