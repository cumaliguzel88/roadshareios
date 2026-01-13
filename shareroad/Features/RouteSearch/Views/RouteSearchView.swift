//
//  RouteSearchView.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI
import CoreLocation

// MARK: - RouteSearchView
/// Full-screen güzergah arama ekranı
struct RouteSearchView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: RouteSearchViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: RouteField?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Durak limit uyarısı
                if viewModel.showStopLimitWarning {
                    HStack {
                        Text("route.stop.limit_warning".localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Text Fields grubu
                textFieldsSection
                
                Divider()
                    .padding(.top, 8)
                
                // İçerik (Sections veya Search Results)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if !viewModel.searchResults.isEmpty {
                            // Arama sonuçları
                            searchResultsSection
                        } else {
                            // Varsayılan sections
                            defaultSections
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("route.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .onAppear {
                // Varsayılan olarak destination'a focus
                focusedField = .destination
                viewModel.activeField = .destination
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showStopLimitWarning)
            .animation(.easeInOut(duration: 0.3), value: viewModel.stops.count)
        }
    }
}

// MARK: - View Components
private extension RouteSearchView {
    
    /// Text fields section (Pickup + Stops + Destination + Controls)
    var textFieldsSection: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 8) {
                // Pickup TextField
                LocationTextField(
                    text: $viewModel.pickupText,
                    placeholder: "route.pickup.my_location".localized,
                    iconColor: .green,
                    isActive: focusedField == .pickup,
                    onTap: {
                        focusedField = .pickup
                        viewModel.activeField = .pickup
                    },
                    onClear: {
                        viewModel.pickupLocation = nil
                        viewModel.clearSearchResults()
                    }
                )
                .focused($focusedField, equals: .pickup)
                
                // Duraklar
                ForEach(0..<viewModel.stops.count, id: \.self) { index in
                    StopTextField(
                        text: Binding(
                            get: { viewModel.stopTexts.indices.contains(index) ? viewModel.stopTexts[index] : "" },
                            set: { newValue in
                                if viewModel.stopTexts.indices.contains(index) {
                                    viewModel.stopTexts[index] = newValue
                                }
                            }
                        ),
                        placeholder: "route.stop.placeholder".localized,
                        isActive: focusedField == .stop(index),
                        onTap: {
                            focusedField = .stop(index)
                            viewModel.activeField = .stop(index)
                        },
                        onClear: {
                            if viewModel.stops.indices.contains(index) {
                                viewModel.stops[index] = nil
                                viewModel.stopTexts[index] = ""
                            }
                        },
                        onRemove: {
                            viewModel.removeStop(at: index)
                        }
                    )
                    .focused($focusedField, equals: .stop(index))
                }
                
                // Destination TextField
                LocationTextField(
                    text: $viewModel.destinationText,
                    placeholder: "route.destination.placeholder".localized,
                    iconColor: .black,
                    isActive: focusedField == .destination,
                    onTap: {
                        focusedField = .destination
                        viewModel.activeField = .destination
                    },
                    onClear: {
                        viewModel.destinationLocation = nil
                        viewModel.clearSearchResults()
                    }
                )
                .focused($focusedField, equals: .destination)
            }
            
            // Kontrol butonları
            VStack(spacing: 8) {
                // Plus butonu (durak ekle)
                Button {
                    viewModel.addStop()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(viewModel.stops.count < viewModel.maxStops ? Color.primary : Color.gray.opacity(0.4))
                        .frame(width: 32, height: 50)
                }
                .disabled(viewModel.stops.count >= viewModel.maxStops)
                
                // Swap butonu
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.swapLocations()
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.gray)
                        .frame(width: 32, height: 50)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    /// Arama sonuçları
    var searchResultsSection: some View {
        ForEach(viewModel.searchResults) { result in
            SearchResultRow(
                location: result,
                icon: "mappin.circle",
                isFavorite: viewModel.isFavorite(result),
                onTap: {
                    viewModel.selectResult(result, for: viewModel.activeField)
                    focusedField = nil
                },
                onFavoriteTap: {
                    viewModel.toggleFavorite(result)
                }
            )
            
            if result.id != viewModel.searchResults.last?.id {
                Divider()
            }
        }
    }
    
    /// Varsayılan sections (Konumum, Son Aramalar, vb.)
    var defaultSections: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Konumum section
            myLocationSection
            
            // Son Aramalar section (varsa)
            if !viewModel.recentSearches.isEmpty {
                recentSearchesSection
            }
            
            // Haritadan seç section
            mapSelectSection
            
            // Kaydedilenler section
            favoritesSection
        }
        .padding(.top, 16)
    }
    
    /// "Konumum" satırı
    var myLocationSection: some View {
        Button {
            // Kullanıcı konumunu seç - bu son aramalara eklenmeyecek
            let myLocation = RouteLocation(
                title: "route.pickup.my_location".localized,
                subtitle: "",
                coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)
            )
            viewModel.selectResult(myLocation, for: viewModel.activeField)
            focusedField = nil
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "location")
                    .foregroundStyle(.blue)
                    .font(.system(size: 18))
                    .frame(width: 24)
                
                Text("route.pickup.my_location".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    /// Son aramalar section
    var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.recentSearches) { location in
                SearchResultRow(
                    location: location,
                    icon: "clock",
                    isFavorite: viewModel.isFavorite(location),
                    onTap: {
                        viewModel.selectResult(location, for: viewModel.activeField)
                        focusedField = nil
                    },
                    onFavoriteTap: {
                        viewModel.toggleFavorite(location)
                    }
                )
                
                if location.id != viewModel.recentSearches.last?.id {
                    Divider()
                }
            }
        }
    }
    
    /// "Konumu Harita Üzerinden Belirle" satırı
    var mapSelectSection: some View {
        Button {
            // TODO: Haritadan seçme ekranı
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.gray)
                    .font(.system(size: 18))
                    .frame(width: 24)
                
                Text("route.map.select_location".localized)
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    /// "Kaydedilen Yerler" satırı ve listesi
    var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleShowFavorites()
                }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 18))
                        .frame(width: 24)
                    
                    Text("route.favorites".localized)
                        .font(.system(size: 16))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if !viewModel.favoriteLocations.isEmpty {
                        Text("\(viewModel.favoriteLocations.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: viewModel.showFavorites ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            
            // Favori listesi (açıksa)
            if viewModel.showFavorites && !viewModel.favoriteLocations.isEmpty {
                Divider()
                
                ForEach(viewModel.favoriteLocations) { location in
                    SearchResultRow(
                        location: location,
                        icon: "star.fill",
                        isFavorite: true,
                        onTap: {
                            viewModel.selectResult(location, for: viewModel.activeField)
                            focusedField = nil
                        },
                        onFavoriteTap: {
                            viewModel.toggleFavorite(location)
                        }
                    )
                    
                    if location.id != viewModel.favoriteLocations.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - StopTextField
/// Durak için özel TextField komponenti
struct StopTextField: View {
    
    @Binding var text: String
    let placeholder: String
    let isActive: Bool
    var onTap: (() -> Void)?
    var onClear: (() -> Void)?
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Durak ikonu (siyah dolu nokta)
            Circle()
                .fill(Color.black)
                .frame(width: 12, height: 12)
            
            // TextField
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .autocapitalization(.words)
                .autocorrectionDisabled()
                .onTapGesture {
                    onTap?()
                }
            
            Spacer()
            
            // Drag handle (görsel)
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundStyle(.gray.opacity(0.5))
            
            // Remove butonu
            Button {
                onRemove?()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.gray)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.white : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color.black.opacity(0.3) : Color.clear, lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    RouteSearchView(viewModel: RouteSearchViewModel())
}
#endif
