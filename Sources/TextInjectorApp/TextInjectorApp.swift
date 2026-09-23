import SwiftUI

@main struct TextInjectorApp: App {
    @StateObject private var permission: PermissionManager
    @StateObject private var controller: InjectionController

    init() {
        let permission = PermissionManager()
        _permission = StateObject(wrappedValue: permission)
        _controller = StateObject(wrappedValue: InjectionController(permission: permission))
    }

    var body: some Scene {
        WindowGroup("TextInjector") {
            MainView(permission: permission, controller: controller)
                .frame(minWidth: 720, minHeight: 660)
        }
        .windowResizability(.contentMinSize)
    }
}
