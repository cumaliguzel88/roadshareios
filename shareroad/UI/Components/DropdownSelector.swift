//
//  DropdownSelector.swift
//  shareroad
//
//  Created by Cumali Güzel on 13.01.2026.
//

import SwiftUI

// MARK: - DropdownSelector
/// Genel amaçlı dropdown seçici komponenti
/// Animasyonlu açılma/kapanma, seçim desteği
struct DropdownSelector<T: Hashable>: View {
    
    // MARK: - Properties
    let title: String
    let options: [T]
    let optionTitle: (T) -> String
    @Binding var selectedOption: T
    @Binding var isExpanded: Bool
    var onSelect: ((T) -> Void)?
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Seçili değer butonu
            selectedButton
            
            // Dropdown menü
            if isExpanded {
                dropdownMenu
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - View Components
private extension DropdownSelector {
    
    /// Seçili değer butonu
    var selectedButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Text(optionTitle(selectedOption))
                    .font(.system(size: 16))
                    .foregroundStyle(Color(.label))
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(optionTitle(selectedOption))")
    }
    
    /// Dropdown menü listesi
    var dropdownMenu: some View {
        VStack(spacing: 0) {
            ForEach(options.filter { $0 != selectedOption }, id: \.self) { option in
                Button {
                    selectedOption = option
                    onSelect?(option)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                    }
                } label: {
                    HStack {
                        Text(optionTitle(option))
                            .font(.system(size: 16))
                            .foregroundStyle(Color(.label))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(Color(.systemBackground))
                }
                .buttonStyle(.plain)
                
                if option != options.filter({ $0 != selectedOption }).last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#if DEBUG
struct DropdownPreview: View {
    @State private var selected = PaymentMethod.cash
    @State private var isOpen = false
    
    var body: some View {
        VStack {
            DropdownSelector(
                title: "Ödeme Yöntemi",
                options: PaymentMethod.allCases,
                optionTitle: { $0.displayName },
                selectedOption: $selected,
                isExpanded: $isOpen
            )
            .padding()
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    DropdownPreview()
}
#endif
