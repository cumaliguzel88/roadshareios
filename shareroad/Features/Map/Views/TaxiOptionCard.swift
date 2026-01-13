//
//  TaxiOptionCard.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI

// MARK: - TaxiOptionCard
/// Taksi seçenek kartı komponenti
/// Sarı/Turkuaz taksi seçeneklerini gösterir
struct TaxiOptionCard: View {
    
    // MARK: - Properties
    let taxiType: TaxiType
    let isSelected: Bool
    let onTap: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Taksi ikonu
                taxiIcon
                
                // İsim ve açıklama
                VStack(alignment: .leading, spacing: 2) {
                    Text(taxiType.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(.label))
                    
                    Text(taxiType.description)
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                // Süre ve kapasite
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ride.time.minutes".localized(with: taxiType.estimatedTime))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(taxiType.accentColor)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                        Text("ride.capacity".localized(with: taxiType.capacity))
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 72)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(taxiType.name), \(taxiType.description)")
    }
}

// MARK: - View Components
private extension TaxiOptionCard {
    
    /// Taksi ikonu - Assets.xcassets'ten gerçek resimler
    var taxiIcon: some View {
        Image(taxiType.iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 60, height: 40)
    }
    
    /// Kart arka planı
    var cardBackground: some View {
        Group {
            if isSelected {
                taxiType.accentColor.opacity(0.1)
            } else {
                Color(.systemBackground)
            }
        }
    }
    
    /// Kart border'ı
    var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                isSelected ? taxiType.accentColor : Color(.systemGray4),
                lineWidth: isSelected ? 2 : 1
            )
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    VStack(spacing: 12) {
        TaxiOptionCard(
            taxiType: .yellow,
            isSelected: true,
            onTap: {}
        )
        
        TaxiOptionCard(
            taxiType: .turquoise,
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
#endif
