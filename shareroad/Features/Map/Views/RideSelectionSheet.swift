//
//  RideSelectionSheet.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI

// MARK: - RideSelectionSheet
/// Alt kısımda sabit duran bottom sheet
/// Taksi seçimi, ödeme yöntemi ve yolculuk oluşturma butonu içerir
struct RideSelectionSheet: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: MapHomeViewModel
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandle
            
            // İçerik
            VStack(spacing: 16) {
                // Arama Çubuğu (Yeni konum)
                MapSearchBar(
                    searchText: $viewModel.searchText,
                    isSearching: $viewModel.isSearching
                )
                
                // Taksi seçenekleri
                taxiOptionsSection
                
                // Ödeme yöntemi dropdown
                paymentDropdown
                
                // Yolculuk oluştur butonu
                createRideButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(sheetBackground)
    }
}

// MARK: - View Components
private extension RideSelectionSheet {
    
    /// Üstteki drag handle göstergesi
    var dragHandle: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 40, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }
    
    /// Taksi seçenekleri bölümü
    var taxiOptionsSection: some View {
        VStack(spacing: 10) {
            ForEach(TaxiType.allCases) { taxiType in
                TaxiOptionCard(
                    taxiType: taxiType,
                    isSelected: viewModel.selectedTaxiType == taxiType,
                    onTap: { viewModel.selectTaxiType(taxiType) }
                )
            }
        }
    }
    
    /// Ödeme yöntemi dropdown
    var paymentDropdown: some View {
        DropdownSelector(
            title: "payment.method".localized,
            options: PaymentMethod.allCases,
            optionTitle: { $0.displayName },
            selectedOption: $viewModel.selectedPaymentMethod,
            isExpanded: $viewModel.isDropdownOpen,
            onSelect: { viewModel.selectPaymentMethod($0) }
        )
    }
    
    /// Yolculuk oluştur butonu
    var createRideButton: some View {
        Button(action: viewModel.createRide) {
            Text("ride.create".localized)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue) // Mavi renk
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!viewModel.canCreateRide)
        .opacity(viewModel.canCreateRide ? 1.0 : 0.6)
        .accessibilityLabel("ride.create".localized)
    }
    
    /// Sheet arka planı
    var sheetBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -4)
            .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            RideSelectionSheet(viewModel: MapHomeViewModel(locationService: LocationService()))
        }
    }
}
#endif
