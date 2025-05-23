// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Shared
import Storage
import XCTest

class FxHomeTopSitesManagerTests: XCTestCase {

    private var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "FxHomeTopSitesManagerTests")
        profile._reopen()

        profile.prefs.clearAll()
    }

    override func tearDown() {
        super.tearDown()

        profile.prefs.clearAll()
        profile._shutdown()
        profile = nil
    }

    func testEmptyData_whenNotLoaded() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertEqual(manager.hasData, false)
        XCTAssertEqual(manager.siteCount, 0)
    }

    func testEmptyData_getSites() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertNil(manager.getSite(index: 0))
        XCTAssertNil(manager.getSite(index: -1))
        XCTAssertNil(manager.getSite(index: 10))
        XCTAssertNil(manager.getSiteDetail(index: 0))
        XCTAssertNil(manager.getSiteDetail(index: -1))
        XCTAssertNil(manager.getSiteDetail(index: 10))
    }

    func testNumberOfRows_default() {
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertEqual(manager.numberOfRows, 2)
    }

    func testNumberOfRows_userChangedDefault() {
        profile.prefs.setInt(3, forKey: PrefsKeys.NumberOfTopSiteRows)
        let manager = FxHomeTopSitesManager(profile: profile)
        XCTAssertEqual(manager.numberOfRows, 3)
    }

    func testLoadTopSitesData_hasDataWithDefaultCalculation() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: nil) {
            XCTAssertEqual(manager.hasData, true)
            XCTAssertEqual(manager.siteCount, 11)
        }
    }

    func testLoadTopSitesData() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.hasData, true)
            XCTAssertEqual(manager.siteCount, 11)
        }
    }

    func testLoadTopSitesData_whenGetSites() {
        let manager = createManager()

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertNotNil(manager.getSite(index: 0))
            XCTAssertNil(manager.getSite(index: -1))
            XCTAssertNotNil(manager.getSite(index: 10))
            XCTAssertNil(manager.getSite(index: 15))

            XCTAssertNotNil(manager.getSiteDetail(index: 0))
            XCTAssertNil(manager.getSiteDetail(index: -1))
            XCTAssertNotNil(manager.getSiteDetail(index: 10))
            XCTAssertNil(manager.getSiteDetail(index: 15))
        }
    }

    // MARK: Google top site

    func testCalculateTopSitesData_hasGoogleTopSite_googlePrefsNil() {
        let manager = createManager()

        // We test that without a pref, google is added
        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
        }
    }

    func testCalculateTopSitesData_hasGoogleTopSiteWithPinnedCount_googlePrefsNi() {
        let manager = createManager(addPinnedSiteCount: 3)

        // We test that without a pref, google is added even with pinned tiles
        testLoadData(manager: manager, numberOfTilesPerRow: 1) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
        }
    }

    func testCalculateTopSitesData_hasNotGoogleTopSite_IfHidden() {
        let manager = createManager(addPinnedSiteCount: 3)

        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteHideKey)

        // We test that having more pinned than available tiles, google tile isn't put in
        testLoadData(manager: manager, numberOfTilesPerRow: 1) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, false)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, false)
        }
    }

    // MARK: Pinned site

    func testCalculateTopSitesData_pinnedSites() {
        let manager = createManager(addPinnedSiteCount: 3)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.hasData, true)
            XCTAssertEqual(manager.siteCount, 14)
            XCTAssertEqual(manager.getSite(index: 0)?.isPinned, true)
        }
    }

    // MARK: Sponsored tiles

    func testLoadTopSitesData_addContile() {
        let manager = createManager()
        manager.addContiles(shouldSucceed: true, contilesCount: 1)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.hasData, true)
            XCTAssertEqual(manager.siteCount, 12)
        }
    }

    func testCalculateTopSitesData_addContileAfterGoogle() {
        let manager = createManager()
        manager.addContiles(shouldSucceed: true, contilesCount: 1)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, true)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, false)
        }
    }

    func testCalculateTopSitesData_doesNotAddContileIfError() {
        let manager = createManager()
        manager.addContiles(shouldSucceed: false, contilesCount: 1)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, false)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, false)
        }
    }

    func testCalculateTopSitesData_doesNotAddContileIfSuccessEmpty() {
        let manager = createManager()
        manager.addContiles(shouldSucceed: true, contilesCount: 0)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, false)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, false)
        }
    }

    func testCalculateTopSitesData_doesNotAddMoreSponsoredTileThanMaximum() {
        let manager = createManager()
        // Max contiles is currently at 2, so it should add 2 contiles only
        manager.addContiles(shouldSucceed: true, contilesCount: 3)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, true)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, true)
            XCTAssertEqual(manager.getSite(index: 3)?.isSponsoredTile, false)
        }
    }

    func testCalculateTopSitesData_doesNotAddSponsoredTileIfDuplicatePinned() {
        let manager = createManager(addPinnedSiteCount: 1)
        manager.addContiles(shouldSucceed: true, contilesCount: 1, duplicateFirstTile: true, pinnedDuplicateTile: true)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, false)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, false)
        }
    }

    func testCalculateTopSitesData_addSponsoredTileIfDuplicateIsNotPinned() {
        let manager = createManager(addPinnedSiteCount: 1)
        manager.addContiles(shouldSucceed: true, contilesCount: 1, duplicateFirstTile: true)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, true)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, false)
        }
    }

    func testCalculateTopSitesData_addNextTileIfContileIsDuplicate() {
        let manager = createManager(addPinnedSiteCount: 1)
        manager.addContiles(shouldSucceed: true, contilesCount: 2, duplicateFirstTile: true, pinnedDuplicateTile: true)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, true)
            XCTAssertEqual(manager.getSite(index: 1)?.title, ContileProviderMock.defaultSuccessData[0].name)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, false)
        }
    }

    func testCalculateTopSitesData_doesNotAddTileIfAllSpacesArePinned() {
        let manager = createManager(addPinnedSiteCount: 12)
        manager.addContiles(shouldSucceed: true, contilesCount: 0)

        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteAddedKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.GoogleTopSiteHideKey)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, false)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, false)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, false)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, false)
        }
    }

    func testCalculateTopSitesData_doesNotAddTileIfAllSpacesArePinnedAndGoogleIsThere() {
        let manager = createManager(addPinnedSiteCount: 11)
        manager.addContiles(shouldSucceed: true, contilesCount: 0)

        testLoadData(manager: manager, numberOfTilesPerRow: 6) {
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleURL, true)
            XCTAssertEqual(manager.getSite(index: 0)?.isGoogleGUID, true)
            XCTAssertEqual(manager.getSite(index: 1)?.isSponsoredTile, false)
            XCTAssertEqual(manager.getSite(index: 2)?.isSponsoredTile, false)
        }
    }
}

// MARK: - Helper methods

// MARK: ContileProviderMock
extension ContileProviderMock {

    static func getContiles(contilesCount: Int,
                            duplicateFirstTile: Bool,
                            pinnedDuplicateTile: Bool) -> [Contile] {

        var defaultData = ContileProviderMock.defaultSuccessData

        if duplicateFirstTile {
            let duplicateTile = pinnedDuplicateTile ? ContileProviderMock.pinnedDuplicateTile : ContileProviderMock.duplicateTile
            defaultData.insert(duplicateTile, at: 0)
        }

        return Array(defaultData.prefix(contilesCount))
    }

    static let pinnedTitle = "A pinned title %@"
    static let pinnedURL = "www.a-pinned-url-%@.com"
    static let title = "A title %@"
    static let url = "www.a-url-%@.com"

    static var pinnedDuplicateTile: Contile {
        return Contile(id: 1,
                       name: String(format: ContileProviderMock.pinnedTitle, "0"),
                       url: String(format: ContileProviderMock.pinnedURL, "0"),
                       clickUrl: "https://www.test.com/click",
                       imageURL: "https://test.com/image0.jpg",
                       imageSize: 200,
                       impressionUrl: "https://test.com",
                       position: 1)
    }

    static var duplicateTile: Contile {
        return Contile(id: 1,
                       name: String(format: ContileProviderMock.title, "0"),
                       url: String(format: ContileProviderMock.url, "0"),
                       clickUrl: "https://www.test.com/click",
                       imageURL: "https://test.com/image0.jpg",
                       imageSize: 200,
                       impressionUrl: "https://test.com",
                       position: 1)
    }
}

// MARK: FxHomeTopSitesManager
extension FxHomeTopSitesManager {

    func addContiles(shouldSucceed: Bool,
                     contilesCount: Int = 0,
                     duplicateFirstTile: Bool = false,
                     pinnedDuplicateTile: Bool = false) {

        let resultContile = ContileProviderMock.getContiles(contilesCount: contilesCount,
                                                            duplicateFirstTile: duplicateFirstTile,
                                                            pinnedDuplicateTile: pinnedDuplicateTile)

        let result = shouldSucceed ? ContileProvider.Result.success(resultContile) : ContileProvider.Result.failure(ContileProviderMock.Error.invalidData)

        let contileProviderMock = ContileProviderMock(result: result)
        contileProvider = contileProviderMock
    }
}

// MARK: FxHomeTopSitesManagerTests
extension FxHomeTopSitesManagerTests {

    func createManager(addPinnedSiteCount: Int = 0) -> FxHomeTopSitesManager {
        let topSitesManager = FxHomeTopSitesManager(profile: profile)

        let historyStub = TopSiteHistoryManagerStub(profile: profile)
        historyStub.addPinnedSiteCount = addPinnedSiteCount
        topSitesManager.topSiteHistoryManager = historyStub

        return topSitesManager
    }

    func testLoadData(manager: FxHomeTopSitesManager, numberOfTilesPerRow: Int?, completion: @escaping () -> Void) {
        let expectation = expectation(description: "Top sites data should be loaded")

        manager.loadTopSitesData {
            if let numberOfTilesPerRow = numberOfTilesPerRow {
                manager.calculateTopSiteData(numberOfTilesPerRow: numberOfTilesPerRow)
            }
            completion()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }
}

// MARK: TopSiteHistoryManagerStub
class TopSiteHistoryManagerStub: TopSiteHistoryManager {

    override func getTopSites(completion: @escaping ([Site]) -> Void) {
        completion(createHistorySites())
    }

    var siteCount = 10
    var addPinnedSiteCount: Int = 0

    func createHistorySites() -> [Site] {
        var sites = [Site]()

        (0..<addPinnedSiteCount).forEach {
            let site = Site(url: String(format: ContileProviderMock.pinnedURL, "\($0)"), title: String(format: ContileProviderMock.pinnedTitle, "\($0)"))
            sites.append(PinnedSite(site: site))
        }

        (0..<siteCount).forEach {
            let site = Site(url: String(format: ContileProviderMock.url, "\($0)"), title: String(format: ContileProviderMock.title, "\($0)"))
            sites.append(site)
        }

        return sites
    }
}
