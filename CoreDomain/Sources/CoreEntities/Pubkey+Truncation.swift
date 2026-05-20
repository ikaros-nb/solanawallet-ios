//
//  Pubkey+Truncation.swift
//  CoreDomain
//
//  Created by Nicolas Bouème on 20/05/2026.
//

public func truncatedAddress(_ pubkey: Pubkey, prefix prefixCount: Int = 4, suffix suffixCount: Int = 4) -> String {
    guard pubkey.count > prefixCount + suffixCount else { return pubkey }
    let head = pubkey.prefix(prefixCount)
    let tail = pubkey.suffix(suffixCount)
    return "\(head)…\(tail)"
}
