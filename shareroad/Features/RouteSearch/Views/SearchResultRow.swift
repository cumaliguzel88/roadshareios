//
//  SearchResultRow.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI
import CoreLocation

// MARK: - SearchResultRow
/// Arama sonucu satırı komponenti
struct SearchResultRow: View {
    
    // MARK: - Properties
    
    let location: RouteLocation
    let icon: String
    var isFavorite: Bool = false
    var showFavoriteButton: Bool = true
    var onTap: (() -> Void)?
    var onFavoriteTap: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 16) {
            // Row'a tıklama
            Button {
                onTap?()
            } label: {
                HStack(spacing: 16) {
                    // İkon
                    Image(systemName: icon)
                        .foregroundStyle(.gray)
                        .font(.system(size: 18))
                        .frame(width: 24)
                    
                    // Başlık ve alt başlık
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        if !location.subtitle.isEmpty {
                            Text(location.subtitle)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            // Favori butonu
            if showFavoriteButton {
                Button {
                    onFavoriteTap?()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .gray.opacity(0.4))
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    VStack(spacing: 0) {
        SearchResultRow(
            location: RouteLocation(
                title: "Yeditepe Üniversitesi",
                subtitle: "Ataşehir/ İstanbul",
                coordinate: .init(latitude: 40.9, longitude: 29.1)
            ),
            icon: "mappin.circle",
            isFavorite: true
        )
        
        Divider()
        
        SearchResultRow(
            location: RouteLocation(
                title: "Yeditepe Üniversitesi Koşuyolu Hastanesi",
                subtitle: "Kadıköy/ İstanbul",
                coordinate: .init(latitude: 40.9, longitude: 29.1)
            ),
            icon: "clock",
            isFavorite: false
        )
    }
    .padding(.horizontal)
}
#endif
