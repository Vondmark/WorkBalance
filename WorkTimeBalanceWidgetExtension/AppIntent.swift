import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "widget.configuration.title" }
    static var description: IntentDescription { "widget.configuration.description" }
}
