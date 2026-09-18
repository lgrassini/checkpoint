import XCTest
@testable import Checkpoint

final class LaunchAtLoginTests: XCTestCase {
    func testReflectsTheServiceStatusOnInit() {
        let service = FakeLoginItemService(status: .enabled)
        let launchAtLogin = LaunchAtLogin(service: service)

        XCTAssertTrue(launchAtLogin.isEnabled)
        XCTAssertFalse(launchAtLogin.needsApproval)
    }

    func testEnablingRegistersAndReflectsTheNewStatus() {
        let service = FakeLoginItemService(status: .notRegistered)
        let launchAtLogin = LaunchAtLogin(service: service)

        launchAtLogin.setEnabled(true)

        XCTAssertEqual(service.registerCount, 1)
        XCTAssertTrue(launchAtLogin.isEnabled)
        XCTAssertNil(launchAtLogin.errorMessage)
    }

    func testDisablingUnregisters() {
        let service = FakeLoginItemService(status: .enabled)
        let launchAtLogin = LaunchAtLogin(service: service)

        launchAtLogin.setEnabled(false)

        XCTAssertEqual(service.unregisterCount, 1)
        XCTAssertFalse(launchAtLogin.isEnabled)
    }

    func testFailedRegistrationSurfacesTheErrorAndStaysOff() {
        let service = FakeLoginItemService(status: .notRegistered)
        service.registerError = TestError.failed
        let launchAtLogin = LaunchAtLogin(service: service)

        launchAtLogin.setEnabled(true)

        XCTAssertFalse(launchAtLogin.isEnabled)
        XCTAssertNotNil(launchAtLogin.errorMessage)
    }

    func testRegistrationNeedingApprovalIsNotReportedAsEnabled() {
        let service = FakeLoginItemService(status: .notRegistered)
        service.statusAfterRegister = .requiresApproval
        let launchAtLogin = LaunchAtLogin(service: service)

        launchAtLogin.setEnabled(true)

        XCTAssertFalse(launchAtLogin.isEnabled)
        XCTAssertTrue(launchAtLogin.needsApproval)
    }

    func testRefreshPicksUpChangesMadeOutsideTheApp() {
        let service = FakeLoginItemService(status: .notRegistered)
        let launchAtLogin = LaunchAtLogin(service: service)
        XCTAssertFalse(launchAtLogin.isEnabled)

        service.status = .enabled
        launchAtLogin.refresh()

        XCTAssertTrue(launchAtLogin.isEnabled)
    }

    func testTheNextAttemptClearsAPreviousError() {
        let service = FakeLoginItemService(status: .notRegistered)
        service.registerError = TestError.failed
        let launchAtLogin = LaunchAtLogin(service: service)
        launchAtLogin.setEnabled(true)
        XCTAssertNotNil(launchAtLogin.errorMessage)

        service.registerError = nil
        launchAtLogin.setEnabled(true)

        XCTAssertNil(launchAtLogin.errorMessage)
        XCTAssertTrue(launchAtLogin.isEnabled)
    }
}

private enum TestError: Error { case failed }

private final class FakeLoginItemService: LoginItemService {
    var status: LoginItemStatus
    var statusAfterRegister: LoginItemStatus = .enabled
    var registerError: Error?
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0

    init(status: LoginItemStatus) {
        self.status = status
    }

    func register() throws {
        registerCount += 1
        if let registerError { throw registerError }
        status = statusAfterRegister
    }

    func unregister() throws {
        unregisterCount += 1
        status = .notRegistered
    }
}
