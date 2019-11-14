import Foundation

public struct Repository: Equatable, Hashable, Codable {
    let _type: _Type?
    let agent: RepositoryAgent?
    let base: URL
    let name: [String: String]
    let description: [String: String]
    let primaryFilter: PrimaryFilter
    let defaultChannel: Channels
    let channels: [Channels]
    let categories: [String: [String: String]]

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
    let name: String
    let version: String
    let url: URL?

    private enum CodingKeys: String, CodingKey {
        case name = "name"
        case version = "version"
        case url = "url"
    }
}

public struct Packages: Hashable, Codable {
    let _type: _Type?
    let base: URL
    let packages: [String: Package]
    
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
    let _type: _Type?
    let id: String
    let name: [String: String]
    let description: [String: String]
    let version: String
    let category: String
    let languages: [String]
    let platform: [String: String]
    let dependencies: [String: String]
    let virtualDependencies: [String: String]
    let installer: Installer

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
    let _type: _Type?
    let url: URL
    let size: UInt64
    let installedSize: UInt64

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
    let _type: _Type?
    let url: URL
    let type: Type_?
    let args: String?
    let uninstallArgs: String?
    let productCode: String
    let requiresReboot: Bool
    let requiresUninstallReboot: Bool
    let size: UInt64
    let installedSize: UInt64

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
    let _type: _Type?
    let url: URL
    let pkgId: String
    let targets: [Targets]
    let requiresReboot: Bool
    let requiresUninstallReboot: Bool
    let size: UInt64
    let installedSize: UInt64

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
    let _type: _Type?
    let virtual: Bool
    let id: String
    let name: [String: String]
    let description: [String: String]
    let version: String
    let url: URL
    let target: VirtualTarget

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
