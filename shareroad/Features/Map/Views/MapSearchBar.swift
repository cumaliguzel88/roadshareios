//
//  MapSearchBar.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI

// MARK: - MapSearchBar
/// Harita üzerindeki arama çubuğu komponenti
/// Büyüteç ikonu + TextField + Konum butonu içerir
struct MapSearchBar: View {
    
    // MARK: - Bindings
    @Binding var searchText: String
    @Binding var isSearching: Bool
    
    // MARK: - Private State
    @FocusState private var isFocused: Bool
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // Büyüteç ikonu
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
                .font(.system(size: 18))
            
            // Arama TextField
            TextField("search.destination.placeholder".localized, text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .autocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isFocused)
                .onChange(of: isFocused) { _, newValue in
                    isSearching = newValue
                }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color(.systemGray6)) // Slightly clearer background on white sheet
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            MapSearchBar(
                searchText: .constant(""),
                isSearching: .constant(false)
            )
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .padding(.top, 60)
    }
}
#endif
