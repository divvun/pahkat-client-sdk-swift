import Foundation

public struct Repository: Equatable, Hashable, Codable {
    public let _type: _Type?
    public let agent: RepositoryAgent?
    public let base: URL
    public let name: [String: String]
    public let description: [String: String]
    public let primaryFilter: PrimaryFilter
    public let defaultChannel: Channels
    public let channels: [Channels]
    public let categories: [String: [String: String]]

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case agent = "agent"
        case base = "base"
        case name = "name"
        case description = "description"
        case primaryFilter = "primaryFilter"
        case defaultChannel = "defaultChannel"
        case channels = "channels"
        case categories = "categories"
    }

    public enum _Type: String, Codable {
        case repository = "Repository"
    }

    public enum PrimaryFilter: String, Codable {
        case category = "category"
        case language = "language"
    }

    public enum Channels: String, Codable {
        case stable = "stable"
        case beta = "beta"
        case alpha = "alpha"
        case nightly = "nightly"
    }
}

public struct RepositoryAgent: Hashable, Codable {
    public let name: String
    public let version: String
    public let url: URL?

    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case version = "version"
        case url = "url"
    }
}

public struct Packages: Hashable, Codable {
    public let _type: _Type?
    public let base: URL
    public let packages: [String: Package]
    
    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case packages = "packages"
        case base = "base"
    }

    public enum _Type: String, Codable {
        case packages = "Packages"
    }
}

public struct Package: Hashable, Codable {
    public let _type: _Type?
    public let id: String
    public let name: [String: String]
    public let description: [String: String]
    public let version: String
    public let category: String
    public let languages: [String]
    public let platform: [String: String]
    public let dependencies: [String: String]
    public let virtualDependencies: [String: String]
    public let installer: Installer

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case id = "id"
        case name = "name"
        case description = "description"
        case version = "version"
        case category = "category"
        case languages = "languages"
        case platform = "platform"
        case dependencies = "dependencies"
        case virtualDependencies = "virtualDependencies"
        case installer = "installer"
    }

    public enum _Type: String, Codable {
        case package = "Package"
    }

    public enum Installer: Hashable, Codable {
        case windowsInstaller(WindowsInstaller)
        case macOsInstaller(MacOsInstaller)
        case tarballInstaller(TarballInstaller)

        public static func ==(lhs: Installer, rhs: Installer) -> Bool {
            switch (lhs, rhs) {
            case let (.windowsInstaller(a), .windowsInstaller(b)):
                return a == b
            case let (.macOsInstaller(a), .macOsInstaller(b)):
                return a == b
            case let (.tarballInstaller(a), .tarballInstaller(b)):
                return a == b
            default:
                return false
            }
        }

        private enum CodingKeys: String, CodingKey {
            case discriminator = "@type"
        }

        private enum DiscriminatorKeys: String, Codable {
            case windowsInstaller = "WindowsInstaller"
            case macOsInstaller = "MacOSInstaller"
            case tarballInstaller = "TarballInstaller"
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .windowsInstaller(value):
                try container.encode(value)
            case let .macOsInstaller(value):
                try container.encode(value)
            case let .tarballInstaller(value):
                try container.encode(value)
            }
        }

        public init(from decoder: Decoder) throws {
            let value = try decoder.singleValueContainer()
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let discriminator = try values.decode(DiscriminatorKeys.self, forKey: .discriminator)

            switch discriminator {
            case .windowsInstaller:
                self = .windowsInstaller(try value.decode(WindowsInstaller.self))
            case .macOsInstaller:
                self = .macOsInstaller(try value.decode(MacOsInstaller.self))
            case .tarballInstaller:
                self = .tarballInstaller(try value.decode(TarballInstaller.self))
            }
        }
    }
}

public struct TarballInstaller: Hashable, Codable {
    public let _type: _Type?
    public let url: URL
    public let size: UInt64
    public let installedSize: UInt64

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case url = "url"
        case size = "size"
        case installedSize = "installedSize"
    }

    public enum _Type: String, Codable {
        case tarballInstaller = "TarballInstaller"
    }
}

public struct WindowsInstaller: Hashable, Codable {
    public let _type: _Type?
    public let url: URL
    public let type: Type_?
    public let args: String?
    public let uninstallArgs: String?
    public let productCode: String
    public let requiresReboot: Bool
    public let requiresUninstallReboot: Bool
    public let size: UInt64
    public let installedSize: UInt64

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case url = "url"
        case type = "type"
        case args = "args"
        case uninstallArgs = "uninstallArgs"
        case productCode = "productCode"
        case requiresReboot = "requiresReboot"
        case requiresUninstallReboot = "requiresUninstallReboot"
        case size = "size"
        case installedSize = "installedSize"
    }

    public enum _Type: String, Codable {
        case windowsInstaller = "WindowsInstaller"
    }

    public enum Type_: String, Codable {
        case msi = "msi"
        case inno = "inno"
        case nsis = "nsis"
    }
}

public struct MacOsInstaller: Hashable, Codable {
    public let _type: _Type?
    public let url: URL
    public let pkgId: String
    public let targets: [Targets]
    public let requiresReboot: Bool
    public let requiresUninstallReboot: Bool
    public let size: UInt64
    public let installedSize: UInt64

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case url = "url"
        case pkgId = "pkgId"
        case targets = "targets"
        case requiresReboot = "requiresReboot"
        case requiresUninstallReboot = "requiresUninstallReboot"
        case size = "size"
        case installedSize = "installedSize"
    }

    public enum _Type: String, Codable {
        case macOsInstaller = "MacOSInstaller"
    }

    public enum Targets: String, Codable {
        case system = "system"
        case user = "user"
    }
}

public struct Virtuals: Hashable, Codable {
    let _type: _Type?
    let virtuals: [String: String]

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case virtuals = "virtuals"
    }

    public enum _Type: String, Codable {
        case virtuals = "Virtuals"
    }
}

public struct Virtual: Hashable, Codable {
    public let _type: _Type?
    public let virtual: Bool
    public let id: String
    public let name: [String: String]
    public let description: [String: String]
    public let version: String
    public let url: URL
    public let target: VirtualTarget

    private enum CodingKeys: String, CodingKey {
        case _type = "@type"
        case virtual = "virtual"
        case id = "id"
        case name = "name"
        case description = "description"
        case version = "version"
        case url = "url"
        case target = "target"
    }

    public enum _Type: String, Codable {
        case virtual = "Virtual"
    }
}

public struct VirtualTarget: Hashable, Codable {
    let registryKey: RegistryKey

    private enum CodingKeys: String, CodingKey {
        case registryKey = "registryKey"
    }
}

public struct RegistryKey: Hashable, Codable {
    let path: String
    let name: String?
    let value: String?
    let valueKind: ValueKind?

    private enum CodingKeys: String, CodingKey {
        case path = "path"
        case name = "name"
        case value = "value"
        case valueKind = "valueKind"
    }

    public enum ValueKind: String, Codable {
        case string = "string"
        case dword = "dword"
        case qword = "qword"
        case etc = "etc"
    }
}

public enum InstallerTarget: Codable {
    case system
    case user
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let v = try container.decode(Int.self)
            if let x = InstallerTarget.from(rawValue: v) {
                self = x
            } else {
                throw NSError(domain: "", code: 0, userInfo: nil)
            }
        } catch {
            let v = try container.decode(String.self)
            if let x = InstallerTarget.from(rawValue: v) {
                self = x
            } else {
                throw error
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.stringValue)
    }
    
    public var intValue: Int {
        switch self {
        case .system:
            return 0
        case .user:
            return 1
        }
    }
    
    public var stringValue: String {
        switch self {
        case .system:
            return "system"
        case .user:
            return "user"
        }
    }
    
    public static func from(rawValue: String) -> InstallerTarget? {
        switch rawValue {
        case "system":
            return InstallerTarget.system
        case "user":
            return InstallerTarget.user
        default:
            return nil
        }
    }
    
    public static func from(rawValue: Int) -> InstallerTarget? {
        switch rawValue {
        case 0:
            return InstallerTarget.system
        case 1:
            return InstallerTarget.user
        default:
            return nil
        }
    }
}

public enum PackageInstallStatus: Int8, Codable {
    case notInstalled = 0
    case upToDate = 1
    case requiresUpdate = 2
    case versionSkipped = 3
    
    // Errors
    case noPackage = -1
    case noInstaller = -2
    case wrongInstallerType = -3
    case parsingVersion = -4
    case invalidInstallPath = -5
    case invalidMetadata = -6
}

extension PackageInstallStatus {
    public func isError() -> Bool {
        return self.rawValue < 0
    }
    
    public var description: String {
        switch self {
        case .notInstalled:
            return Strings.notInstalled
        case .upToDate:
            return Strings.installed
        case .requiresUpdate:
            return Strings.updateAvailable
        case .versionSkipped:
            return Strings.versionSkipped
        case .noPackage:
            return Strings.errorUnknownPackage
        case .noInstaller:
            return Strings.errorNoInstaller
        case .wrongInstallerType:
            // TODO: localise
            return Strings.errorNoInstaller
        case .parsingVersion:
            return Strings.errorInvalidVersion
        case .invalidInstallPath:
            // TODO: localise
            return Strings.errorNoInstaller
        case .invalidMetadata:
            // TODO: localise
            return Strings.errorNoInstaller
        }
    }
}

public struct PackageStatusResponse: Codable {
    public let status: PackageInstallStatus
    public let target: InstallerTarget
}

public struct PackageKeyParams: Equatable, Hashable {
    private(set) var platform: String?
    private(set) var arch: String?
    private(set) var version: String?
    private(set) var channel: String?

    init?(queryItems: [URLQueryItem]) {
        for item in queryItems {
            let name = item.name
            let value = item.value

            switch name {
            case "platform":
                self.platform = value
            case "arch":
                self.arch = value
            case "version":
                self.version = value
            case "channel":
                self.channel = value
            default:
                continue
            }
        }

        if platform == nil && arch == nil && version == nil && channel == nil {
            return nil
        }
    }
}

extension Array where Element == URLQueryItem {
    static func from(_ params: PackageKeyParams) -> [URLQueryItem] {
        var out = [URLQueryItem]()

        if let platform = params.platform {
            out.append(URLQueryItem(name: "platform", value: platform))
        }

        if let arch = params.arch {
            out.append(URLQueryItem(name: "arch", value: arch))
        }

        if let version = params.version {
            out.append(URLQueryItem(name: "version", value: version))
        }

        if let channel = params.channel {
            out.append(URLQueryItem(name: "channel", value: channel))
        }

        return out
    }
}

public enum PackageKeyError: Error {
    case invalidURL(String)
}

public class PackageKey: Equatable, Hashable, Codable, CustomDebugStringConvertible {
    public let repositoryURL: URL
    public let id: String
    public let params: PackageKeyParams?

    public required init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let url = try c.decode(String.self)

        let k = try PackageKey.from(urlString: url)
        self.repositoryURL = k.repositoryURL
        self.id = k.id
        self.params = k.params
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(self.toString())
    }

    public var debugDescription: String {
        "URL: \(repositoryURL), id: \(id), params: \(String(describing: params))"
    }

    public init(repositoryURL: URL, id: String, params: PackageKeyParams? = nil) {
        self.repositoryURL = repositoryURL
        self.id = id
        self.params = params
    }

    public static func from(url: URL) throws -> PackageKey {
        guard let id = url.pathComponents.last else {
            fatalError("this is impossible")
        }

        var newUrl = url.deletingLastPathComponent()

        if let end = newUrl.pathComponents.last, end != "packages" {
            throw PackageKeyError.invalidURL(url.absoluteString)
        }

        newUrl = newUrl.deletingLastPathComponent()

        var components = URLComponents(url: newUrl, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = PackageKeyParams(queryItems: queryItems)

        components.fragment = nil
        components.query = nil

        let repoURL = components.url!

        return PackageKey(repositoryURL: repoURL, id: id, params: params)
    }

    public static func from(urlString: String) throws -> PackageKey {
        guard let url = URL(string: urlString) else {
            throw PackageKeyError.invalidURL(urlString)
        }

        return try PackageKey.from(url: url)
    }

    public static func == (lhs: PackageKey, rhs: PackageKey) -> Bool {
        lhs.repositoryURL == rhs.repositoryURL
            && lhs.id == rhs.id
            && lhs.params == rhs.params
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(repositoryURL)
        hasher.combine(id)
        hasher.combine(params)
    }

    public func toString() -> String {
        var urlBuilder = URLComponents(url: repositoryURL
            .appendingPathComponent("packages")
            .appendingPathComponent(id), resolvingAgainstBaseURL: false)!

        urlBuilder.queryItems = params.map { [URLQueryItem].from($0) }
        return urlBuilder.url!.absoluteString
    }
}

@objc public class RepositoryIndex: NSObject, Decodable, Comparable {
    public let meta: Repository
    public let channel: Repository.Channels
    private let packagesMeta: Packages
    private let virtualsMeta: Virtuals
    
    public var statuses: [PackageKey: PackageStatusResponse] = [:]
    
    init(repository: Repository, packages: Packages, virtuals: Virtuals, channel: Repository.Channels) {
        self.meta = repository
        self.packagesMeta = packages
        self.virtualsMeta = virtuals
        self.channel = channel
    }
    
    public var packages: [String: Package] {
        return packagesMeta.packages
    }
    
    public var virtuals: [String: String] {
        return virtualsMeta.virtuals
    }
    
//    func url(for package: Package) -> URL {
//        return packagesMeta.base.appendingPathComponent(package.id)
//    }
    
    public func status(for key: PackageKey) -> PackageStatusResponse? {
        return statuses[key]
    }
    
    public func package(for key: PackageKey) -> Package? {
//        if key.url != meta.base.absoluteString || key.channel != channel.rawValue {
//            return nil
//        }
//
        return packages[key.id]
    }
    
    @available(*, deprecated, message: "use status(for:)")
    public func status(forPackage package: Package) -> PackageStatusResponse? {
        if let key = statuses.keys.first(where: { $0.id == package.id }) {
            return self.status(for: key)
        }
        return nil
    }
    
//    func status(forPackage package: Package) -> PackageStatusResponse? {
//        return statuses[package.id]
//    }
    
    public func absoluteKey(for package: Package) -> PackageKey {
        return PackageKey(repositoryURL: self.meta.base, id: package.id)
    }
    
    func set(statuses: [PackageKey: PackageStatusResponse]) {
        self.statuses = statuses
    }
    
    private enum CodingKeys: String, CodingKey {
        case meta = "meta"
        case channel = "channel"
        case packagesMeta = "packages"
        case virtualsMeta = "virtuals"
    }
    
    public static func ==(lhs: RepositoryIndex, rhs: RepositoryIndex) -> Bool {
        return lhs.meta == rhs.meta &&
            lhs.packagesMeta == rhs.packagesMeta &&
            lhs.virtualsMeta == rhs.virtualsMeta
    }
    
    public static func <(lhs: RepositoryIndex, rhs: RepositoryIndex) -> Bool {
        // BTree keys break if you don't break contention yourself...
        if lhs.meta.nativeName == rhs.meta.nativeName {
            return lhs.hashValue < rhs.hashValue
        }
        return lhs.meta.nativeName < rhs.meta.nativeName
    }
    
//    override var hashValue: Int {
//        return meta.hashValue ^ packagesMeta.hashValue ^ virtualsMeta.hashValue
//    }
}


extension Package.Installer {
    public var size: Int64 {
        switch self {
        case let .windowsInstaller(installer):
            return Int64(installer.size)
        case let .macOsInstaller(installer):
            return Int64(installer.size)
        case let .tarballInstaller(installer):
            return Int64(installer.size)
        }
    }
}

extension Package: Comparable {
    public static func <(lhs: Package, rhs: Package) -> Bool {
        switch lhs.nativeName.localizedCaseInsensitiveCompare(rhs.nativeName) {
        case .orderedAscending:
            return true
        default:
            return false
        }
    }
}

fileprivate let iso8601fmt: DateFormatter = {
    let iso8601fmt = DateFormatter()
    iso8601fmt.calendar = Calendar(identifier: .iso8601)
    iso8601fmt.locale = Locale(identifier: "en_US_POSIX")
    iso8601fmt.timeZone = TimeZone(secondsFromGMT: 0)
    iso8601fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return iso8601fmt
}()

fileprivate let localeFmt: DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateStyle = .short
    fmt.timeStyle = .short
    return fmt
}()

extension Date {
    public var iso8601: String {
        return iso8601fmt.string(from: self)
    }
    
    public var localeString: String {
        return localeFmt.string(from: self)
    }
}

extension String {
    public var iso8601: Date? {
        return iso8601fmt.date(from: self)
    }
}

extension Package {
    public var nativeVersion: String {
        // Try to make this at least a _bit_ efficient
        if self.version.hasSuffix("Z") {
            return self.version.iso8601?.localeString ?? self.version
        }
        
        return self.version
    }
    
    public var nativeName: String {
        for code in Locale(identifier: Strings.languageCode).derivedIdentifiers {
            if let name = self.name[code] {
                return name
            }
        }
        
        return self.name["en"] ?? ""
    }

#if os(macOS)
    public var macOSInstaller: MacOsInstaller? {
        switch installer {
        case .macOsInstaller(let x):
            return x
        default:
            return nil
        }
    }
#endif
    
    public var tarballInstaller: TarballInstaller? {
        switch installer {
        case .tarballInstaller(let x):
            return x
        default:
            return nil
        }
    }
}

extension Repository {
    public var nativeName: String {
        for code in Locale(identifier: Strings.languageCode).derivedIdentifiers {
            if let name = self.name[code] {
                return name
            }
        }
        
        return self.name["en"] ?? ""
    }
    
    public func nativeCategory(for key: String) -> String {
        for code in Locale(identifier: Strings.languageCode).derivedIdentifiers {
            guard let map = self.categories[code] else {
                continue
            }
            
            return map[key] ?? key
        }
        
        return key
    }
}

public enum PackageActionType: String, Codable {
    case install = "install"
    case uninstall = "uninstall"
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let v = try container.decode(Int.self)
            if let x = PackageActionType.from(rawValue: v) {
                self = x
            } else {
                throw NSError(domain: "", code: 0, userInfo: nil)
            }
        } catch {
            let v = try container.decode(String.self)
            if let x = PackageActionType.from(rawValue: v) {
                self = x
            } else {
                throw error
            }
        }
    }
    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encode(self.intValue)
//    }
//
//    public var intValue: Int {
//        switch self {
//        case .install:
//            return 0
//        case .uninstall:
//            return 1
//        }
//    }
    
    static func from(rawValue: String) -> PackageActionType? {
        switch rawValue {
        case "install":
            return .install
        case "uninstall":
            return .uninstall
        default:
            return nil
        }
    }
    
    static func from(rawValue: Int) -> PackageActionType? {
        switch rawValue {
        case 0:
            return .install
        case 1:
            return .uninstall
        default:
            return nil
        }
    }
}

public struct TransactionAction<Target: Codable>: Codable {
    public let action: PackageActionType
    public let id: PackageKey
    public let target: Target
    
    public static func install(_ id: PackageKey, target: Target) -> TransactionAction {
        return TransactionAction(action: .install, id: id, target: target)
    }
    
    public static func uninstall(_ id: PackageKey, target: Target) -> TransactionAction {
        return TransactionAction(action: .uninstall, id: id, target: target)
    }
}

extension TransactionAction where Target == Empty {
    public static func install(_ id: PackageKey) -> TransactionAction {
        return TransactionAction(action: .install, id: id, target: Empty.instance)
    }
    public static func uninstall(_ id: PackageKey, target: Target) -> TransactionAction {
        return TransactionAction(action: .uninstall, id: id, target: Empty.instance)
    }
}
