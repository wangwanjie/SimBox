import Foundation
import ServiceManagement

enum LoginItemManager {
    enum ToggleResult {
        case enabled
        case disabled
        /// 已注册但需要用户在“系统设置 › 通用 › 登录项”里手动允许。
        case requiresApproval
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func toggle() throws -> ToggleResult {
        let service = SMAppService.mainApp
        switch service.status {
        case .enabled:
            try service.unregister()
            return .disabled
        case .requiresApproval:
            // 已经登记过，只差用户授权，重复 register 无效，直接带用户去设置页。
            SMAppService.openSystemSettingsLoginItems()
            return .requiresApproval
        default:
            try service.register()
            if service.status == .requiresApproval {
                SMAppService.openSystemSettingsLoginItems()
                return .requiresApproval
            }
            return .enabled
        }
    }
}
