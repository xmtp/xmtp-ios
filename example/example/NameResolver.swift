import SwiftUI
import XMTPiOS

// A name resolver for XMTP identities.
//
// By default this returns `0x1234...1234` for the identifier.
// TODO: resolve ENS and TBD other names
@Observable
class NameResolver {
    let ethereum = ObservableCache<String>(defaultValue: { identifier in
        return "\(identifier.prefix(6))...\(identifier.suffix(4))"
    })
    
    init() {
        ethereum.loader = self.resolveEthereumName
    }
    
    subscript(_ identity: PublicIdentity?) -> ObservableItem<String> {
        if identity == nil {
            return ObservableItem(identifier: "") // nil-ish
        }
        // For ethereum identifiers, try to resolve it.
        if case .ethereum = identity!.kind {
            return ethereum[identity!.identifier]
        }
        // For unknown identifier types, just show the abbreviated edition.
        return ObservableItem(
            identifier: identity!.identifier,
            defaultValue: identity!.abbreviated
        )
    }
    
    func resolveEthereumName(_ identifier: String) async throws -> String {
        print("resolving ethereum name for \(identifier)")
        
        // TODO: resolve the ENS name for this address
        // TODO: reverse("\(identifier).addr.reverse") -> name
        // TODO: ref https://github.com/wevm/viem/blob/main/src/actions/ens/getEnsName.ts
        return "\(identifier.prefix(6))...\(identifier.suffix(4))"
    }
}

extension PublicIdentity {
    var abbreviated: String {
        switch kind {
        case .ethereum:
            return "\(identifier.prefix(6))...\(identifier.suffix(4))"
        default:
            return "\(identifier.prefix(6))...\(identifier.suffix(4))"
        }
    }
}
